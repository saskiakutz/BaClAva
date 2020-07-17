import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
import os
import time
import csv
import multiprocessing
from model_table import TableModel


class View_run(qtw.QWidget):
    submitted = qtc.pyqtSignal(object, object)
    status = True

    # noinspection PyArgumentList
    def __init__(self):
        super().__init__()

        main_layout = qtw.QVBoxLayout()

        parameter_layout = qtw.QFormLayout()
        heading = qtw.QLabel("Bayesian Clustering")
        parameter_layout.addRow(heading)
        heading_font = qtg.QFont('Arial', 32, qtg.QFont.Bold)
        heading_font.setStretch(qtg.QFont.ExtraExpanded)
        heading.setFont(heading_font)

        self.roi_x_min = qtw.QSpinBox(
            self,
            minimum=0,
            maximum=10000,
            value=0
        )
        self.roi_x_max = qtw.QSpinBox(
            self,
            minimum=1,
            maximum=100000,
            value=3000
        )

        roi_layout_x = qtw.QHBoxLayout()
        roi_layout_x.layout().addWidget(self.roi_x_min)
        roi_layout_x.layout().addWidget(self.roi_x_max)
        #
        self.roi_y_min = qtw.QSpinBox(
            self,
            minimum=0,
            maximum=10000,
            value=0
        )
        self.roi_y_max = qtw.QSpinBox(
            self,
            minimum=1,
            maximum=100000,
            value=3000
        )
        roi_layout_y = qtw.QHBoxLayout()
        roi_layout_y.layout().addWidget(self.roi_y_min)
        roi_layout_y.layout().addWidget(self.roi_y_max)

        self.th_min = qtw.QSpinBox(
            self,
            minimum=1,
            maximum=100,
            value=5
        )
        self.th_max = qtw.QSpinBox(
            self,
            minimum=2,
            maximum=1000,
            value=500
        )
        self.th_step = qtw.QSpinBox(
            self,
            minimum=1,
            maximum=100,
            value=5
        )
        threshold_layout = qtw.QHBoxLayout()
        threshold_layout.layout().addWidget(self.th_min)
        threshold_layout.layout().addWidget(self.th_max)
        threshold_layout.layout().addWidget(self.th_step)

        self.r_min = qtw.QSpinBox(
            self,
            minimum=1,
            maximum=100,
            value=5
        )
        self.r_max = qtw.QSpinBox(
            self,
            minimum=2,
            maximum=1000,
            value=300
        )
        self.r_step = qtw.QSpinBox(
            self,
            minimum=1,
            maximum=100,
            value=5
        )
        radius_layout = qtw.QHBoxLayout()
        radius_layout.layout().addWidget(self.r_min)
        radius_layout.layout().addWidget(self.r_max)
        radius_layout.layout().addWidget(self.r_step)

        # TODO: parameters
        self.b_inputs = {
            "model": qtw.QComboBox(),
            "datasource": qtw.QComboBox(),
            "clustermethod": qtw.QComboBox(),
            "parallelization": qtw.QCheckBox(),
            "cores": qtw.QSpinBox(
                self,
                minimum=1,
                maximum=multiprocessing.cpu_count(),
                value=multiprocessing.cpu_count() / 2
            ),
            "ROI x size [nm]": roi_layout_x,
            "ROI y size [nm]": roi_layout_y,
            "Radius sequence": radius_layout,
            "Threshold sequence": threshold_layout,
            "Dirichlet process: \u03B1": qtw.QDoubleSpinBox(
                self,
                minimum=0,
                maximum=100,
                singleStep=1,
                value=20
            ),
            "background proportion": qtw.QDoubleSpinBox(
                self,
                minimum=0,
                maximum=1,
                singleStep=0.1,
                value=0.5
            )
        }

        models = ('Gaussian(prec)', 'no other model implemented')
        self.b_inputs["model"].addItems(models)
        self.b_inputs["model"].model().item(1).setEnabled(False)

        datasources = ('simulation', 'experiment')
        self.b_inputs["datasource"].addItems(datasources)

        clustermethods = ("Ripley' K based", "DBSCAN", "ToMATo")
        self.b_inputs["clustermethod"].addItems(clustermethods)

        if os.name == 'nt':
            self.b_inputs["parallelization"].setDisabled(True)
            # TODO: test on Windows system and Mac

        self.b_inputs["cores"].setDisabled(True)
        self.b_inputs["parallelization"].toggled.connect(self.b_inputs["cores"].setEnabled)

        self.b_inputs["datasource"].currentIndexChanged[int].connect(self.on_currentIndexChanged)

        for label, widget in self.b_inputs.items():
            parameter_layout.addRow(label, widget)

        self.dir_btn = qtw.QPushButton("Select data directory")
        self.dir_btn.clicked.connect(self.chooseFile)
        self.dir_line = qtw.QLineEdit("select data directory")
        self.dir_line.setReadOnly(True)
        self.dir_line.textChanged.connect(lambda x: self.dir_line.setReadOnly(x == ''))

        parameter_layout.addRow(self.dir_btn, self.dir_line)

        main_layout.addLayout(parameter_layout)

        col_layout = qtw.QHBoxLayout()
        name_layout = qtw.QHBoxLayout()

        col_inputs = {
            'x column': qtw.QSpinBox(
                self,
                minimum=1,
                maximum=100,
                singleStep=1,
                value=1
            ),
            'y column': qtw.QSpinBox(
                self,
                minimum=1,
                maximum=100,
                singleStep=1,
                value=2
            ),
            'SD column': qtw.QSpinBox(
                self,
                minimum=1,
                maximum=100,
                singleStep=1,
                value=3
            )
        }

        for label, widget in col_inputs.items():
            name_layout.addWidget(qtw.QLabel(label))
            col_layout.addWidget(widget)

        # test_layout = qtw.QHBoxLayout()
        # self.x_col = qtw.QSpinBox(
        #     self,
        #     minimum=1,
        #     maximum=100,
        #     singleStep=1,
        #     value=1
        # )
        # test_layout.addWidget(self.x_col)

        main_layout.addLayout(name_layout)
        main_layout.addLayout(col_layout)

        self.tableview = qtw.QTableView()
        main_layout.addWidget(self.tableview)

        button_layout = qtw.QHBoxLayout()

        self.start_btn = qtw.QPushButton(
            "start",
            # checkable=True,
            clicked=self.start_run
            # TODO: grey out start button after starting run
        )
        self.start_btn.setDisabled(self.status)
        self.dir_line.textChanged.connect(lambda x: self.start_btn.setDisabled(x == ''))

        self.cancel_btn = qtw.QPushButton(
            "cancel"
        )

        button_layout.addWidget(self.start_btn)
        button_layout.addWidget(self.cancel_btn)

        main_layout.addLayout(button_layout)

        self.setLayout(main_layout)

    def on_currentIndexChanged(self):
        if self.b_inputs["datasource"].currentText() == "experiment":
            self.roi_x_min.setDisabled(True)
            self.roi_x_max.setDisabled(True)
            self.roi_y_min.setDisabled(True)
            self.roi_y_max.setDisabled(True)
        else:
            self.roi_x_min.setDisabled(False)
            self.roi_x_max.setDisabled(False)
            self.roi_y_min.setDisabled(False)
            self.roi_y_max.setDisabled(False)

    def chooseFile(self):
        filename, _ = qtw.QFileDialog.getOpenFileName(
            self,
            "Select data file",
            qtc.QDir.homePath(),
            'txt files (*.txt);; csv files (*.csv) ;; All files (*)'
        )
        if filename:
            self.model = TableModel(filename)
            self.tableview.setModel(self.model)
            self.dir_line.setText(os.path.dirname(os.path.dirname(filename)))

    def btnstate(self, change_status):
        print("here")
        print(change_status)
        if not change_status:
            self.status = change_status
            self.start_btn.setDisabled(self.status)
            print(self.status)

    def disableButton(self):
        self.start_btn.setDisabled(self.status)
        self.start_btn.repaint()

    def toggleStateAndButton(self):
        self.start_btn.setDisabled(self.status)
        self.status = not self.status
        self.start_btn.repaint()

    def start_run(self):
        # if self.start_btn.isChecked():
        # self.disableButton()
        # self.toggleStateAndButton()
        # # self.status = not self.status
        # print("button pressed")
        #
        # time.sleep(5)
        #
        # self.toggleStateAndButton()

        if self.b_inputs['parallelization'].isChecked():
            parallel = {
                "parallel": 1,
                "cores": self.b_inputs['cores'].value()
            }
        else:
            parallel = {
                "parallel": 0
            }
        data = {
            'directory': self.dir_line.text(),
            'model': self.b_inputs['model'].currentText(),
            'datasource': self.b_inputs['datasource'].currentText(),
            'clustermethod': self.b_inputs['clustermethod'].currentText(),
            'rmin': self.r_min.value(),
            'rmax': self.r_max.value(),
            'rstep': self.r_step.value(),
            'thmin': self.th_min.value(),
            'thmax': self.th_max.value(),
            'thstep': self.th_step.value(),
            'roixmin': self.roi_x_min.value(),
            'roixmax': self.roi_x_max.value(),
            'roiymin': self.roi_y_min.value(),
            'roiymax': self.roi_y_max.value(),
            'alpha': self.b_inputs['Dirichlet process: \u03B1'].value(),
            'background': self.b_inputs['background proportion'].value()
        }
        self.submitted.emit(data, parallel)

    def show_error(self, error):
        qtw.QMessageBox.critical(None, 'Error', error)

    # TODO: import option for stored config files
