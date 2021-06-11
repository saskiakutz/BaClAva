# Title     : Module 2
# Objective : Connections GUI module 2
# Written by: Saskia Kutz

import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from run.view_run_module import ViewRun
from run.model_run_module import Model_run


class MainWindowBayesian(qtw.QWidget):
    """Connecting GUI to module 2"""

    start_bayesian = qtc.pyqtSignal(str)
    finished_bayesian = qtc.pyqtSignal(str)

    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here

        self.run_model = Model_run()
        self.run_view = ViewRun()
        self.setLayout(qtw.QVBoxLayout())
        self.layout().addWidget(self.run_view)

        self.run_thread = qtc.QThread(parent=self)
        self.run_model.moveToThread(self.run_thread)
        self.run_model.finished.connect(self.run_thread.quit)
        self.run_model.finished.connect(self.on_finished)
        self.run_thread.start()

        self.run_view.submitted.connect(self.run_model.set_data)
        self.run_view.startrun.connect(self.run_thread.start)
        self.run_view.startrun.connect(self.on_start)
        self.run_view.submitted.connect(self.run_model.check_income)
        self.run_model.error.connect(self.run_view.show_error)

        # End main UI code
        self.show()

    def on_start(self):
        """Statusbar update upon start"""

        self.start_bayesian.emit('Bayesian clustering running.')

    def on_finished(self):
        """GUI preparation after finish:
        - thread termination
        - statusbar update
        """

        self.run_thread.quit()
        self.run_model.deleteLater()
        self.run_view.start_btn.setEnabled(True)
        self.finished_bayesian.emit('Bayesian clustering finished.')
