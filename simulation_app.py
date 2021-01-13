import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from sim.view_simulation_module import View_sim
from sim.model_simulation_module import Model_sim


class MainWindow(qtw.QMainWindow):

    # noinspection PyArgumentList,PyTypeChecker
    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here

        menubar = self.menuBar()
        file_menu = menubar.addMenu('File')
        help_menu = menubar.addMenu('Help')
        help_action = help_menu.addAction("Help")
        quit_action = file_menu.addAction("Quit", self.close)

        self.setWindowTitle("Simulation 2.0")
        self.model = Model_sim()
        self.view = View_sim()
        self.setCentralWidget(self.view)

        self.sim_thread = qtc.QThread()
        self.model.moveToThread(self.sim_thread)
        self.model.finished.connect(self.sim_thread.quit)
        self.sim_thread.start()

        self.view.submitted.connect(self.model.set_data)
        self.view.startsim.connect(self.sim_thread.start)
        self.view.submitted.connect(self.model.print_income)
        self.model.error.connect(self.view.show_error)

        self.model.finished.connect(self.on_finished)

        status_bar = qtw.QStatusBar()
        self.setStatusBar(status_bar)
        status_bar.showMessage('cluster simulation')
        # TODO: status_bar update messages

        # End main UI code
        self.show()

    def on_finished(self):
        self.statusBar().showMessage('Simulation finished.')
        self.view.start_btn.setEnabled(True)


if __name__ == '__main__':
    app = qtw.QApplication(sys.argv)
    mw = MainWindow()
    sys.exit(app.exec())
