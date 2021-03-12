import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from sim.view_simulation_module import View_sim
from sim.model_simulation_module import Model_sim


class MainWindow_simulation(qtw.QWidget):
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

        self.sim_thread = qtc.QThread()
        self.model.moveToThread(self.sim_thread)
        self.model.finished.connect(self.sim_thread.quit)
        self.sim_thread.start()

        self.view.submitted.connect(self.model.set_data)
        self.view.startsim.connect(self.sim_thread.start)
        self.view.startsim.connect(self.on_started)
        self.view.submitted.connect(self.model.print_income)
        self.model.error.connect(self.view.show_error)

        self.model.finished.connect(self.on_finished)

        #     status_bar = qtw.QStatusBar()
        #     self.setStatusBar(status_bar)
        #     status_bar.showMessage('cluster simulation')
        #     # TODO: status_bar update messages
        #
        # End main UI code
        self.show()

    def on_started(self):
        # self.view.start_btn.setEnabled(False)
        self.start_sim.emit('Simulating clusters.')

    def on_finished(self):
        # self.statusBar().showMessage('Simulation finished.')
        self.sim_thread.quit()
        self.sim_thread.deleteLater()
        self.view.start_btn.setEnabled(True)
        self.finished_sim.emit('Simulation finished.')


if __name__ == '__main__':
    app = qtw.QApplication(sys.argv)
    mw = MainWindow_simulation()
    sys.exit(app.exec())
