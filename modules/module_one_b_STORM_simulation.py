import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from sim.view_simulation_module_STORM import ViewSTORM
from sim.model_simulation_module_STORM import Model_STORM


class MainWindow_simulation_STORM(qtw.QWidget):
    finished_STORM_sim = qtc.pyqtSignal(str)
    start_STORM_sim = qtc.pyqtSignal(str)

    # noinspection PyArgumentList,PyTypeChecker
    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here

        self.model = Model_STORM()
        self.view = ViewSTORM()
        self.setLayout(qtw.QVBoxLayout())
        self.layout().addWidget(self.view)

        self.sim_STORM_thread = qtc.QThread()
        self.model.moveToThread(self.sim_STORM_thread)
        self.model.finished.connect(self.sim_STORM_thread.quit)
        self.sim_STORM_thread.start()

        self.view.submitted.connect(self.model.set_data)
        self.view.start_STORM.connect(self.sim_STORM_thread.start)
        self.view.start_STORM.connect(self.on_started)
        self.view.submitted.connect(self.model.print_income)
        self.model.error.connect(self.view.show_error)

        self.model.finished.connect(self.on_finished)

        # End main UI code
        self.show()

    def on_started(self):
        # self.view.start_btn.setEnabled(False)
        self.start_STORM_sim.emit('Simulating blinking clusters.')

    def on_finished(self):
        # self.statusBar().showMessage('Simulation finished.')
        self.sim_STORM_thread.quit()
        self.sim_STORM_thread.deleteLater()
        self.view.start_btn.setEnabled(True)
        self.finished_STORM_sim.emit('Simulation finished.')

# if __name__ == '__main__':
#     app = qtw.QApplication(sys.argv)
#     mw = MainWindow_simulation()
#     sys.exit(app.exec())
