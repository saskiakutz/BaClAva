import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc


class View_STORM(qtw.QWidget):
    submitted = qtc.pyqtSignal(object)
    startsim = qtc.pyqtSignal()

    # noinspection PyArgumentList
    def __init__(self):
        super().__init__()
        self.setLayout(qtw.QFormLayout())

        self.roi_x = qtw.QSpinBox(
            self,
            minimum=0,
            maximum=10000,
            value=31
        )
        self.roi_y = qtw.QSpinBox(
            self,
            minimum=1,
            maximum=100000,
            value=31
        )

        roi_layout = qtw.QHBoxLayout()
        roi_layout.layout().addWidget(self.roi_x)
        roi_layout.layout().addWidget(self.roi_y)

        self.PSF_FWHM = qtw.QSpinBox(
            self,
            minimum=0,
            maximum=10000,
            value=0
        )
        self.PSF_intensity = qtw.QSpinBox(
            self,
            minimum=1,
            maximum=100000,
            value=3000
        )

        PSF_layout = qtw.QHBoxLayout()
        PSF_layout.layout().addWidget(self.PSF_FWHM)
        PSF_layout.layout().addWidget(self.PSF_intensity)

        self.on_rate = qtw.QDoubleSpinBox(
            self,
            minimum=0,
            maximum=100,
            decimals=1,
            singleStep=1,
            value=5
        )
        self.off_rate = qtw.QDoubleSpinBox(
            self,
            minimum=0,
            maximum=10000,
            decimals=1,
            singleStep=0.1,
            value=10
        )

        rate_layout = qtw.QHBoxLayout()
        rate_layout.layout().addWidget(self.on_rate)
        rate_layout.layout().addWidget(self.off_rate)
        #
        # self.beta_a = qtw.QDoubleSpinBox(
        #     self,
        #     minimum=0,
        #     maximum=100,
        #     value=1
        # )
        # self.beta_b = qtw.QDoubleSpinBox(
        #     self,
        #     minimum=0,
        #     maximum=100,
        #     value=1
        # )
        # beta_layout = qtw.QHBoxLayout()
        # beta_layout.layout().addWidget(self.beta_a)
        # beta_layout.layout().addWidget(self.beta_b)

        self.inputs = {
            "number of clusters": qtw.QSpinBox(
                self,
                value=10,
                minimum=1,
                maximum=1000,
                singleStep=1
            ),
            "cluster radius [nm]": qtw.QSpinBox(
                self,
                minimum=0,
                maximum=10000,
                singleStep=1,
                value=50
            ),
            "density or number of molecules per cluster": qtw.QSpinBox(
                self,
                minimum=1,
                maximum=10000,
                singleStep=1,
                value=100
            ),
            "density or number of molecules in the background": qtw.QDoubleSpinBox(
                self,
                minimum=0,
                maximum=100000,
                singleStep=1,
                value=100
            ),
            "blinking rate": qtw.QComboBox(),
            "blinking rate (on, off) [s⁻¹]": rate_layout,
            "PFS(FWHM [nm], intensity)": PSF_layout,
            "camera ROI size [px]": roi_layout,
            "pixel size [nm]": qtw.QDoubleSpinBox(
                self,
                minimum=0,
                maximum=200,
                singleStep=0.1,
                value=100
            ),
            "exposure time [s]": qtw.QSpinBox(
                self,
                minimum=1,
                maximum=500,
                singleStep=1,
                value=20
            ),
            "number of frames per simulation": qtw.QSpinBox(
                self,
                minimum=1,
                maximum=1000000000,
                singleStep=1000,
                value=50000
            ),
            "number of simulations": qtw.QSpinBox(
                self,
                minimum=1,
                maximum=1000000,
                singleStep=1,
                value=10
            )
        }
        models = ('AF647', 'AF488', 'CF680', 'other dye')
        self.inputs["blinking rate"].addItems(models)

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

        self.start_btn.setDisabled(True)
        self.dir_line.textChanged.connect(lambda x: self.start_btn.setDisabled(x == ''))

        self.layout().addRow(self.start_btn)

    def saveFile(self):
        filename = qtw.QFileDialog.getExistingDirectory(
            self,
            "Select directory",
            qtc.QDir.homePath()
        )
        self.dir_line.setText(filename)

    def start_sim(self):
        data = {
            'directory': self.dir_line.text(),
            'nclusters': self.inputs['number of clusters'].value(),
            'molspercluster': self.inputs['number of molecules per cluster'].value(),
            'model': self.inputs['model'].currentText(),
            'sdcluster': self.inputs['standard deviation [nm]'].value(),
            'background': self.inputs['background percentage'].value(),
            'nsim': self.inputs['number of simulations'].value(),
            'roixmin': self.roi_x.value(),
            'roixmax': self.roi_y.value(),
            'roiymin': self.PSF_FWHM.value(),
            'roiymax': self.PSF_intensity.value(),
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
        qtw.QMessageBox.critical(None, 'Error', error)

    # TODO: multimerisation as a checkbox option, if chosen: option to state number of molecules, proportion multimers,
    # import stored sim_parameters.txt
