import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from run.view_run_module import View_run
from run.model_run_module import Model_run


class MainWindow_Bayesian(qtw.QWidget):
    statusbar = qtc.pyqtSignal(str)

    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here

        self.run_model = Model_run()
        self.run_view = View_run()
        self.setLayout(qtw.QVBoxLayout())
        self.layout().addWidget(self.run_view)

        self.run_thread = qtc.QThread()
        self.run_model.moveToThread(self.run_thread)
        self.run_model.finished.connect(self.run_thread.quit)
        self.run_model.finished.connect(self.on_finished)
        self.run_thread.start()

        self.run_view.submitted.connect(self.run_model.set_data)
        self.run_view.startrun.connect(self.run_thread.start)
        self.run_view.startrun.connect(self.on_start)
        self.run_view.submitted.connect(self.run_model.check_income)
        self.run_model.error.connect(self.run_view.show_error)
        # TODO: status_bar update messages

        # End main UI code
        self.show()

    def on_start(self):
        self.statusbar.emit('Bayesian clustering running.')

    def on_finished(self):
        self.run_model.finished.connect(self.on_finished)
        self.statusbar.emit('Bayesian clustering finished.')
        # status_bar = qtw.QStatusBar()
        # self.setStatusBar(status_bar)
        # status_bar.showMessage('Bayesian clustering')
        # self.statusBar().showMessage('Bayesian clustering finished.')
        # self.run_view.start_btn.setEnabled(True)


if __name__ == '__main__':
    app = qtw.QApplication(sys.argv)
    mw = MainWindow()
    sys.exit(app.exec())
