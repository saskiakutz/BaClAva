import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from post.view_post_module import View_post
from post.model_post_module import Model_post


class MainWindow_post(qtw.QWidget):
    started_post = qtc.pyqtSignal(str)
    finished_post = qtc.pyqtSignal(str)

    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here

        self.post_model = Model_post()
        self.post_view = View_post()
        self.setLayout(qtw.QVBoxLayout())
        self.layout().addWidget(self.post_view)

        self.post_thread = qtc.QThread()
        self.post_model.moveToThread(self.post_thread)
        self.post_model.finished.connect(self.post_thread.quit)
        self.post_thread.start()

        self.post_view.submitted.connect(self.post_model.set_data)
        self.post_view.startpost.connect(self.post_thread.start)
        self.post_view.startpost.connect(self.on_started)
        self.post_view.submitted.connect(self.post_model.check_income)
        self.post_model.error.connect(self.post_view.show_error)

        self.post_model.finished.connect(self.on_finished)
        self.post_model.finished.connect(self.post_view.show_data)

        # status_bar = qtw.QStatusBar()
        # self.setStatusBar(status_bar)
        # status_bar.showMessage('Post processing')
        # TODO: status_bar update messages

        # End main UI code
        self.show()

    def on_started(self):
        self.started_post.emit('Post processing.')

    def on_finished(self):
        self.post_view.start_btn.setEnabled(True)
        self.finished_post.emit('Post processing finished.')


if __name__ == '__main__':
    app = qtw.QApplication(sys.argv)
    mw = MainWindow()
    sys.exit(app.exec())
