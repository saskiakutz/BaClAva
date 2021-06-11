# Title     : Module 1a
# Objective : Connections GUI module 1a
# Written by: Saskia Kutz

import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from sim.view_simulation_module import View_sim
from sim.model_simulation_module import Model_sim


class MainWindowSimulation(qtw.QWidget):
    """Connecting GUI to module 1a"""

    finished_sim = qtc.pyqtSignal(str)
    start_sim = qtc.pyqtSignal(str)

    # noinspection PyArgumentList,PyTypeChecker
    def __init__(self):
        """MainWindow constructor"""

        super().__init__()
        # Main UI code goes here

        self.model = Model_sim()
        self.view = View_sim()
        self.setLayout(qtw.QVBoxLayout())
        self.layout().addWidget(self.view)

        self.sim_thread = qtc.QThread(parent=self)
        self.model.moveToThread(self.sim_thread)
        self.model.finished.connect(self.sim_thread.quit)
        self.sim_thread.start()

        self.view.submitted.connect(self.model.set_data)
        self.view.startsim.connect(self.sim_thread.start)
        self.view.startsim.connect(self.on_started)
        self.view.submitted.connect(self.model.print_income)
        self.model.error.connect(self.view.show_error)

        self.model.finished.connect(self.on_finished)

        # End main UI code
        self.show()

    def on_started(self):
        """Status bar update upon start"""

        self.start_sim.emit('Simulating clusters.')

    def on_finished(self):
        """GUI preparation after finish of calculations:
        - thread termination
        - statusbar update
        """

        self.sim_thread.quit()
        self.model.deleteLater()
        self.view.start_btn.setEnabled(True)
        self.finished_sim.emit('Simulation finished.')
