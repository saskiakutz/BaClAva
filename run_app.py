import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc

from view_run_module import View_run
from model_run_module import Model_run
from model_table import TableModel


class MainWindow(qtw.QMainWindow):

    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here
        menubar = self.menuBar()
        file_menu = menubar.addMenu('File')
        help_menu = menubar.addMenu('Help')
        help_action = help_menu.addAction('Help')
        quit_action = file_menu.addAction('Quit', self.close)

        self.setWindowTitle("Bayesian clustering 1.0")
        self.run_model = Model_run()
        self.run_view = View_run()
        self.setCentralWidget(self.run_view)

        self.run_thread = qtc.QThread()
        self.run_model.moveToThread(self.run_thread)
        self.run_model.finished.connect(self.run_thread.quit)
        self.run_thread.start()

        self.run_view.submitted.connect(self.run_model.set_data)
        self.run_view.startsim.connect(self.run_thread.start)
        self.run_view.submitted.connect(self.run_model.check_income)
        self.run_model.error.connect(self.run_view.show_error)

        self.run_model.finished.connect(self.on_finished)

        status_bar = qtw.QStatusBar()
        self.setStatusBar(status_bar)
        status_bar.showMessage('Bayesian clustering')
        # TODO: status_bar update messages

        # End main UI code
        self.show()

    def on_finished(self):
        self.statusBar().showMessage('Bayesian clustering finished.')
        self.run_view.start_btn.setEnabled(True)


if __name__ == '__main__':
    app = qtw.QApplication(sys.argv)
    mw = MainWindow()
    sys.exit(app.exec())
