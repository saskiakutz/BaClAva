import sys
from os import path, mkdir
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc

from view_module import View
from model_module import Model


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

        self.view = View()
        self.setCentralWidget(self.view)

        self.model = Model()

        self.view.submitted.connect(self.model.print_income)
        self.model.error.connect(self.view.show_error)

        status_bar = qtw.QStatusBar()
        self.setStatusBar(status_bar)
        status_bar.showMessage('cluster simulation')

        # End main UI code
        self.show()


if __name__ == '__main__':
    app = qtw.QApplication(sys.argv)
    mw = MainWindow()
    sys.exit(app.exec())
