# Title     : View for module 1a
# Objective : View setup of module 1a
# Written by: Saskia Kutz

from PyQt5 import QtCore as qtc
from PyQt5 import QtGui as qtg
from PyQt5 import QtWidgets as qtw


class ViewSim(qtw.QWidget):
    """View part of module 1a"""

    submitted = qtc.pyqtSignal(object)
    startsim = qtc.pyqtSignal()

    # noinspection PyArgumentList
    def __init__(self):
        """Setup of all GUI sections and options"""

        super().__init__()
        self.setLayout(qtw.QFormLayout())

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

        self.alpha = qtw.QDoubleSpinBox(
            self,
            minimum=0,
            maximum=100,
            singleStep=1,
            value=5
        )
        self.beta = qtw.QDoubleSpinBox(
            self,
            minimum=0,
            maximum=100,
            decimals=6,
            singleStep=0.000001,
            value=0.166667
        )

        gamma_layout = qtw.QHBoxLayout()
        gamma_layout.layout().addWidget(self.alpha)
        gamma_layout.layout().addWidget(self.beta)

        self.beta_a = qtw.QDoubleSpinBox(
            self,
            minimum=0,
            maximum=100,
            value=1
        )
        self.beta_b = qtw.QDoubleSpinBox(
            self,
            minimum=0,
            maximum=100,
            value=1
        )
        beta_layout = qtw.QHBoxLayout()
        beta_layout.layout().addWidget(self.beta_a)
        beta_layout.layout().addWidget(self.beta_b)

        self.inputs = {
            "number of clusters": qtw.QSpinBox(
                self,
                value=10,
                minimum=1,
                maximum=1000,
                singleStep=1
            ),
            "number of molecules per cluster": qtw.QSpinBox(
                self,
                minimum=1,
                maximum=10000,
                singleStep=1,
                value=100
            ),
            "model": qtw.QComboBox(),
            "standard deviation [nm]": qtw.QSpinBox(
                self,
                minimum=0,
                maximum=10000,
                singleStep=1,
                value=50
            ),
            "background percentage": qtw.QDoubleSpinBox(
                self,
                minimum=0,
                maximum=1,
                singleStep=0.1,
                value=0.5
            ),
            "number of simulations": qtw.QSpinBox(
                self,
                minimum=1,
                maximum=1000000,
                singleStep=1,
                value=10
            ),
            "ROI x size [nm]": roi_layout_x,
            "ROI y size [nm]": roi_layout_y,
            "Gamma parameters (\u03B1, \u03B2)": gamma_layout,
            "background distribution": beta_layout
        }
        models = ('Gaussian', 'no other model implemented')
        self.inputs["model"].addItems(models)
        self.inputs["model"].model().item(1).setEnabled(False)

        for label, widget in self.inputs.items():
            self.layout().addRow(label, widget)

        self.dir_btn = qtw.QPushButton("Select directory")
        self.dir_btn.clicked.connect(self.saveFile)
        self.dir_line = qtw.QLineEdit("select directory")
        self.dir_line.setReadOnly(True)
        self.dir_line.textChanged.connect(lambda x: self.dir_line.setReadOnly(x == ''))

        self.layout().addRow(self.dir_btn, self.dir_line)

        self.start_btn = qtw.QPushButton(
            'simulate',
            clicked=self.start_sim
        )

        self.start_btn.setFont(qtg.QFont('Arial', 15))
        self.start_btn.setDisabled(True)
        self.dir_line.textChanged.connect(lambda x: self.start_btn.setDisabled(x == ''))

        self.layout().addRow(self.start_btn)

    def saveFile(self):
        """directory selection for storage"""

        filename = qtw.QFileDialog.getExistingDirectory(
            self,
            "Select directory",
            qtc.QDir.homePath()
        )
        self.dir_line.setText(filename)

    def start_sim(self):
        """start simulation:
        - data collection from input
        - data emission
        """

        data = {
            'directory': self.dir_line.text(),
            'nclusters': self.inputs['number of clusters'].value(),
            'molspercluster': self.inputs['number of molecules per cluster'].value(),
            'model': self.inputs['model'].currentText(),
            'sdcluster': self.inputs['standard deviation [nm]'].value(),
            'background': self.inputs['background percentage'].value(),
            'nsim': self.inputs['number of simulations'].value(),
            'roixmin': self.roi_x_min.value(),
            'roixmax': self.roi_x_max.value(),
            'roiymin': self.roi_y_min.value(),
            'roiymax': self.roi_y_max.value(),
            'alpha': self.alpha.value(),
            'beta': self.beta.value(),
            'a': self.beta_a.value(),
            'b': self.beta_b.value()
        }
        self.start_btn.setDisabled(True)
        self.startsim.emit()
        print(data)
        self.submitted.emit(data)

    def show_error(self, error):
        """error message in separate window"""

        qtw.QMessageBox.critical(None, 'Error', error)

    # TODO: multimerisation as a checkbox option, if chosen: option to state number of molecules, proportion multimers,
