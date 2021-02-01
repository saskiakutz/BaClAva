import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
from PyQt5.QtGui import QPalette, QColor
from module_one_simulation import MainWindow_simulation
from module_two_Bayesian import MainWindow_Bayesian
from module_three_post import MainWindow_post
from Bayesian_software_view import View_software


class Main_Window(qtw.QMainWindow):

    def __init__(self):
        super().__init__()
        self.message = None

        menubar = self.menuBar()
        file_menu = menubar.addMenu('File')
        help_menu = menubar.addMenu('Help')
        help_action = help_menu.addAction("Help")
        quit_action = file_menu.addAction("Quit", self.close)

        self.main_view = View_software()
        self.setCentralWidget(self.main_view)
        # self.tab_widget = qtw.QTabWidget()
        # self.setCentralWidget(self.tab_widget)

        # self.subwidget_1 = qtw.QWidget(self)
        # self.grid_layout = qtw.QGridLayout()
        # self.subwidget_1.setLayout(self.grid_layout)
        # self.subwidget_2 = qtw.QWidget(self)
        # self.grid_layout2 = qtw.QGridLayout()
        # self.subwidget_2.setLayout(self.grid_layout2)
        # self.subwidget_3 = qtw.QWidget(self)
        # self.grid_layout3 = qtw.QGridLayout()
        # self.subwidget_3.setLayout(self.grid_layout3)
        # self.tab_widget.addTab(self.subwidget_1, 'Module 1: Simulation')
        # self.main_simulation = MainWindow_simulation()
        # self.subwidget_1.layout().addWidget(self.main_simulation)
        # self.tab_widget.addTab(self.subwidget_2, 'Module 2: Bayesian engine')
        # self.main_run = MainWindow_Bayesian()
        # self.subwidget_2.layout().addWidget(self.main_run)
        # self.tab_widget.addTab(self.subwidget_3, 'Module 3: Postprocessing')
        # self.main_post = MainWindow_post()
        # self.subwidget_3.layout().addWidget(self.main_post)
        # # self.tab_widget.currentChanged(self.set_statusbar)

        status_bar = qtw.QStatusBar()
        self.setStatusBar(status_bar)
        status_bar.showMessage('cluster simulation')
        # TODO: status_bar update messages

        # End main UI code
        self.show()

    @qtc.pyqtSlot(str)
    def set_statusbar(self, message):
        self.message = message
        self.statusBar().showMessage(self.message)

    # def on_finished(self):
    #     self.statusBar().showMessage('Simulation finished.')
    #     # self.view.start_btn.setEnabled(True)


class MainWindow(qtw.QMainWindow):

    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here
        self.view = Main_Window()
        self.setWindowTitle('Bayesian Software')
        self.setCentralWidget(self.view)
        # End main UI code
        self.show()


if __name__ == '__main__':
    app = qtw.QApplication(sys.argv)
    app.setStyle('Fusion')
    palette = QPalette()
    palette.setColor(QPalette.Window, QColor(53, 53, 53))
    palette.setColor(QPalette.WindowText, qtc.Qt.white)
    palette.setColor(QPalette.Window, QColor(53, 53, 53))
    palette.setColor(QPalette.WindowText, qtc.Qt.white)
    palette.setColor(QPalette.Base, QColor(25, 25, 25))
    palette.setColor(QPalette.AlternateBase, QColor(53, 53, 53))
    palette.setColor(QPalette.ToolTipBase, qtc.Qt.black)
    palette.setColor(QPalette.ToolTipText, qtc.Qt.white)
    palette.setColor(QPalette.Text, qtc.Qt.white)
    palette.setColor(QPalette.Button, QColor(53, 53, 53))
    palette.setColor(QPalette.ButtonText, qtc.Qt.white)
    palette.setColor(QPalette.BrightText, qtc.Qt.red)
    palette.setColor(QPalette.Link, QColor(42, 130, 218))
    palette.setColor(QPalette.Highlight, QColor(42, 130, 218))
    palette.setColor(QPalette.HighlightedText, qtc.Qt.black)
    app.setPalette(palette)
    mw = MainWindow()
    sys.exit(app.exec())
