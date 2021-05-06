import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from sim.view_simulation_module_smlm import ViewSMLM
from sim.model_simulation_module_smlm import ModelSMLM


class MainWindowSimulationSMLM(qtw.QWidget):
    finished_STORM_sim = qtc.pyqtSignal(str)
    start_STORM_sim = qtc.pyqtSignal(str)

    # noinspection PyArgumentList,PyTypeChecker
    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here

        self.model_smlm = ModelSMLM()
        self.storm_view = ViewSMLM()
        self.setLayout(qtw.QVBoxLayout())
        self.layout().addWidget(self.storm_view)

        self.sim_STORM_thread = qtc.QThread(parent=self)
        self.model_smlm.moveToThread(self.sim_STORM_thread)
        self.model_smlm.finished.connect(self.sim_STORM_thread.quit)
        self.sim_STORM_thread.start()

        self.storm_view.submitted.connect(self.model_smlm.set_data)
        self.storm_view.start_STORM.connect(self.sim_STORM_thread.start)
        self.storm_view.start_STORM.connect(self.on_started)
        self.storm_view.submitted.connect(self.model_smlm.print_income)
        self.model_smlm.error.connect(self.storm_view.show_error)

        self.model_smlm.finished.connect(self.on_finished)

        self.storm_view.cancel_STORM.connect(self.on_cancel)
        # End main UI code
        self.show()

    def on_started(self):
        # self.storm_view.start_btn.setEnabled(False)
        self.start_STORM_sim.emit('Simulating blinking clusters.')

    def on_finished(self):
        # self.statusBar().showMessage('Simulation finished.')
        self.sim_STORM_thread.quit()
        self.model_smlm.deleteLater()
        self.sim_STORM_thread.deleteLater()
        self.storm_view.start_btn.setEnabled(True)
        self.finished_STORM_sim.emit('Simulation finished.')

    def on_cancel(self):
        self.sim_STORM_thread.quit()
        self.sim_STORM_thread.deleteLater()
        self.storm_view.start_btn.setEnabled(True)
        self.finished_STORM_sim.emit('SMLM simulation cancelled.')

