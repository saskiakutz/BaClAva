import sys
import webbrowser
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc
from PyQt5 import QtGui as qtg
from PyQt5.QtGui import QPalette, QColor
from Bayesian_software_view import ViewSoftware



class ModuleWindow(qtw.QMainWindow):
    """
    Main class for
    - starting the main GUI window and its menubar
    - connecting all modules start and finish signals with the statusbar update
    """

    def __init__(self):
        super().__init__()
        self.message = None

        menubar = self.menuBar()
        file_menu = menubar.addMenu('File')
        help_menu = menubar.addMenu('Help')
        quit_action = file_menu.addAction("Quit", self.close)

        self.main_view = ViewSoftware()
        self.setCentralWidget(self.main_view)
        # self.simulation = MainWindow_simulation()
        # self.simulation.finished_sim.connect(self.set_statusbar)
        self.main_view.main_simulation.start_sim.connect(self.set_statusbar)
        self.main_view.main_simulation.finished_sim.connect(self.set_statusbar)
        self.main_view.main_simulation_STORM.start_STORM_sim.connect(self.set_statusbar)
        self.main_view.main_simulation_STORM.finished_STORM_sim.connect(self.set_statusbar)
        self.main_view.main_run.start_bayesian.connect(self.set_statusbar)
        self.main_view.main_run.finished_bayesian.connect(self.set_statusbar)
        self.main_view.main_post.started_post.connect(self.set_statusbar)
        self.main_view.main_post.finished_post.connect(self.set_statusbar)

        self.status_bar = qtw.QStatusBar()
        self.setStatusBar(self.status_bar)
        self.status_bar.showMessage('Select a module.')

        help_action = qtw.QAction('Help', self, triggered=lambda: self.statusBar().showMessage('open BaClAva on GitHub...'))
        help_action.triggered.connect(self.open_help)
        help_menu.addAction(help_action)

        # End main UI code
        self.show()

    @qtc.pyqtSlot(str)
    def set_statusbar(self, message):
        self.status_bar.showMessage(message)

    @staticmethod
    def open_help():
        webbrowser.open(url='https://github.com/saskiakutz/BaClAva')


class MainWindow(qtw.QMainWindow):

    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here
        self.view = ModuleWindow()
        self.setWindowIcon(qtg.QIcon('./readme_images/logo.png'))
        self.setWindowTitle('BaClAva')
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
