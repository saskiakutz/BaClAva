import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
import os
import multiprocessing


class View_run(qtw.QWidget):
    submitted = qtc.pyqtSignal(object, object)

    # noinspection PyArgumentList
    def __init__(self):
        super().__init__()
        self.setLayout(qtw.QFormLayout())

        heading = qtw.QLabel("Bayesian Clustering")
        self.layout().addRow(heading)
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
        # form.layout().addRow(self.roi_x_min, self.roi_x_max)
        roi_layout_x = qtw.QHBoxLayout()
        roi_layout_x.layout().addWidget(self.roi_x_min)
        roi_layout_x.layout().addWidget(self.roi_x_max)

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
        # form.layout().addRow(self.roi_x_min, self.roi_x_max)
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
            value=300
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
            self.layout().addRow(label, widget)

        self.dir_btn = qtw.QPushButton("Select data directory")
        self.dir_btn.clicked.connect(self.chooseFile)
        self.dir_line = qtw.QLineEdit("select data directory")
        self.dir_line.setReadOnly(True)
        self.dir_line.textChanged.connect(lambda x: self.dir_line.setReadOnly(x == ''))

        self.layout().addRow(self.dir_btn, self.dir_line)

        self.start_btn = qtw.QPushButton(
            "start",
            clicked=self.start_run
        )
        self.start_btn.setDisabled(True)
        self.dir_line.textChanged.connect(lambda x: self.start_btn.setDisabled(x == ''))

        self.layout().addRow(self.start_btn)

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
        filename = qtw.QFileDialog.getExistingDirectory(
            self,
            "Select data directory",
            qtc.QDir.homePath()
        )
        self.dir_line.setText(filename)

    def start_run(self):
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
