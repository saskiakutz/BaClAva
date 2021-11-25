# Title     : View for module 2
# Objective : View setup of module 2
# Written by: Saskia Kutz

import multiprocessing
import os

from PyQt5 import QtCore as qtc
from PyQt5 import QtGui as qtg
from PyQt5 import QtWidgets as qtw

from run.model_table_pd import DataFrameModel


class ViewRun(qtw.QWidget):
    """View part of module 2"""

    submitted = qtc.pyqtSignal(object, object)
    startrun = qtc.pyqtSignal()

    # noinspection PyArgumentList
    def __init__(self):
        """Setup of all GUI sections and options"""

        super().__init__()

        self.model = None
        main_layout = qtw.QVBoxLayout()

        parameter_layout = qtw.QFormLayout()

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
            # "ROI x size [nm]": roi_layout_x,
            # "ROI y size [nm]": roi_layout_y,
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

        datasources = ('simulation (module 1a)',
                       'localised data (experiment or module 1b)',
                       'TrackMate: spots in tracks')
        self.b_inputs["datasource"].addItems(datasources)

        clustermethods = ("ToMATo", "DBSCAN", "Ripley' K based", "DBSCAN 2")
        self.b_inputs["clustermethod"].addItems(clustermethods)

        # if os.name == 'nt':
        #     self.b_inputs["parallelization"].setDisabled(True)

        self.b_inputs["cores"].setDisabled(True)
        self.b_inputs["parallelization"].toggled.connect(self.b_inputs["cores"].setEnabled)

        self.b_inputs["datasource"].currentIndexChanged[int].connect(self.on_current_index_changed)

        for label, widget in self.b_inputs.items():
            parameter_layout.addRow(label, widget)

        self.dir_btn = qtw.QPushButton("Select data directory")
        self.dir_btn.clicked.connect(self.choose_file)
        self.dir_line = qtw.QLineEdit("select data directory")
        self.dir_line.setReadOnly(True)
        self.dir_line.textChanged.connect(lambda x: self.dir_line.setReadOnly(x == ''))

        parameter_layout.addRow(self.dir_btn, self.dir_line)

        main_layout.addLayout(parameter_layout)

        col_layout = qtw.QHBoxLayout()
        name_layout = qtw.QHBoxLayout()

        self.col_inputs = {
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

        for label, widget in self.col_inputs.items():
            name_layout.addWidget(qtw.QLabel(label))
            col_layout.addWidget(widget)

        main_layout.addLayout(name_layout)
        main_layout.addLayout(col_layout)

        self.tableview = qtw.QTableView()
        main_layout.addWidget(self.tableview)

        button_layout = qtw.QHBoxLayout()

        self.start_btn = qtw.QPushButton(
            "start",
            # checkable=True,
            clicked=self.start_run
        )
        self.start_btn.setFont(qtg.QFont('Arial', 15))
        self.start_btn.setDisabled(True)
        self.dir_line.textChanged.connect(lambda x: self.start_btn.setDisabled(x == ''))

        self.cancel_btn = qtw.QPushButton(
            "cancel"  # TODO: cancel action
        )
        self.cancel_btn.setFont(qtg.QFont('Arial', 15))

        button_layout.addWidget(self.start_btn)
        button_layout.addWidget(self.cancel_btn)

        main_layout.addLayout(button_layout)

        self.setLayout(main_layout)

    def on_current_index_changed(self):
        """set options depending on experiment or simulation"""

        self.dir_line.setText("select data directory")
        self.start_btn.setDisabled(True)

    def choose_file(self):
        """file selection of calculations"""

        filename, _ = qtw.QFileDialog.getOpenFileName(
            self,
            "Select data file",
            qtc.QDir.homePath(),
            'hdf5 files (*.h5);; txt files (*.txt);; csv files (*.csv) ;; All files (*)'
        )
        if filename:
            # self.model = TableModel(filename)
            self.model = DataFrameModel(filename)
            self.tableview.setModel(self.model)
            if self.b_inputs['datasource'].currentText() == "simulation (module 1a)":
                if filename.split('.')[1] == 'h5':
                    self.dir_line.setText(os.path.dirname(filename))
                else:
                    self.dir_line.setText(os.path.dirname(os.path.dirname(filename)))
            else:
                text_files = [f for f in os.listdir(os.path.dirname(filename)) if f == 'r_vs_thresh.txt']
                if len(text_files) == 0:
                    self.dir_line.setText(os.path.dirname(filename))
                else:
                    self.dir_line.setText(os.path.dirname(os.path.dirname(filename)))

    def start_run(self):
        """start the Bayesian engine:
        - data collection from input
        - data emission
        """

        if self.b_inputs['parallelization'].isChecked():
            parallel = {
                "parallel": 1,
                "cores": self.b_inputs['cores'].value()
            }
        else:
            parallel = {
                "parallel": 0
            }
        trackmate = False
        if self.b_inputs['datasource'].currentText() == 'simulation (module 1a)':
            self.b_inputs['datasource'] = 'simulation'
        else:
            if self.b_inputs['datasource'].currentText() == 'TrackMate: spots in tracks':
                trackmate = True
            self.b_inputs['datasource'] = 'experiment'
        data = {
            'directory': self.dir_line.text(),
            'model': self.b_inputs['model'].currentText(),
            'datasource': self.b_inputs['datasource'],
            'clustermethod': self.b_inputs['clustermethod'].currentText(),
            'rmin': self.r_min.value(),
            'rmax': self.r_max.value(),
            'rstep': self.r_step.value(),
            'thmin': self.th_min.value(),
            'thmax': self.th_max.value(),
            'thstep': self.th_step.value(),
            # 'roixmin': self.roi_x_min.value(),
            # 'roixmax': self.roi_x_max.value(),
            # 'roiymin': self.roi_y_min.value(),
            # 'roiymax': self.roi_y_max.value(),
            'xcol': self.col_inputs['x column'].value(),
            'ycol': self.col_inputs['y column'].value(),
            'sdcol': self.col_inputs['SD column'].value(),
            'alpha': self.b_inputs['Dirichlet process: \u03B1'].value(),
            'background': self.b_inputs['background proportion'].value()
        }

        self.start_btn.setDisabled(True)
        self.startrun.emit()
        self.submitted.emit(data, parallel, trackmate)

    def show_error(self, error):
        """error message in separate window"""

        qtw.QMessageBox.critical(None, 'Error', error)

    # TODO: import option for stored config files
