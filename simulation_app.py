import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc


class Model(qtc.QObject):
    pass


class View(qtw.QWidget):
    submitted = qtc.pyqtSignal(str, object)

    def __init__(self):
        super().__init__()
        self.setLayout(qtw.QFormLayout())


class MainWindow(qtw.QMainWindow):

    # noinspection PyArgumentList
    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here

        menubar = self.menuBar()
        file_menu = menubar.addMenu('File')
        help_menu = menubar.addMenu('Help')
        help_action = help_menu.addAction("Help")
        quit_action = file_menu.addAction("Quit", self.close)

        self.setWindowTitle("Simulation 1.0")
        form = qtw.QWidget()
        self.setCentralWidget(form)
        form.setLayout(qtw.QFormLayout())

        heading = qtw.QLabel("Simulation")
        form.layout().addRow(heading)
        heading_font = qtg.QFont('Arial', 32, qtg.QFont.Bold)
        heading_font.setStretch(qtg.QFont.ExtraExpanded)
        heading.setFont(heading_font)

        roi_x_min = qtw.QSpinBox(
            self,
            minimum=0,
            maximum=10000,
            value=0
        )
        roi_x_max = qtw.QSpinBox(
            self,
            minimum=1,
            maximum=100000,
            value=3000
        )
        # form.layout().addRow(self.roi_x_min, self.roi_x_max)
        roi_layout_x = qtw.QHBoxLayout()
        roi_layout_x.layout().addWidget(roi_x_min)
        roi_layout_x.layout().addWidget(roi_x_max)

        roi_y_min = qtw.QSpinBox(
            self,
            minimum=0,
            maximum=10000,
            value=0
        )
        roi_y_max = qtw.QSpinBox(
            self,
            minimum=1,
            maximum=100000,
            value=3000
        )
        # form.layout().addRow(self.roi_x_min, self.roi_x_max)
        roi_layout_y = qtw.QHBoxLayout()
        roi_layout_y.layout().addWidget(roi_y_min)
        roi_layout_y.layout().addWidget(roi_y_max)

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
            "ROI y size [nm]": roi_layout_y
        }
        models = ('Gaussian', 'no other model implemented')
        self.inputs["model"].addItems(models)

        for label, widget in self.inputs.items():
            form.layout().addRow(label, widget)

        self.dir_btn = qtw.QPushButton("Select directory")
        self.dir_btn.clicked.connect(self.saveFile)
        self.dir_line = qtw.QLineEdit("select directory")

        form.layout().addRow(self.dir_btn, self.dir_line)

        self.start_btn = qtw.QPushButton(
            'simulate',
            clicked=self.start_sim
        )

        form.layout().addRow(self.start_btn)

        status_bar = qtw.QStatusBar()
        self.setStatusBar(status_bar)
        status_bar.showMessage('cluster simulation')
        # End main UI code
        self.show()

    def saveFile(self):
        filename = qtw.QFileDialog.getExistingDirectory(
            self,
            "Select directory",
            qtc.QDir.homePath()
        )
        self.dir_line.setText(filename)

    def start_sim(self):
        directory = self.dir_line.text()
        self.submitted.emit(directory, self.inputs)


if __name__ == '__main__':
    app = qtw.QApplication(sys.argv)
    mw = MainWindow()
    sys.exit(app.exec())
