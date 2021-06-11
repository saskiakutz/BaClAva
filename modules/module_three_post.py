# Title     : Module 3
# Objective : Connections GUI module 3
# Written by: Saskia Kutz

import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from post.view_post_module import ViewPost
from post.model_post_module import ModelPost


class MainWindowPost(qtw.QWidget):
    """Connecting GUI to module 3"""

    started_post = qtc.pyqtSignal(str)
    finished_post = qtc.pyqtSignal(str)

    def __init__(self):
        """MainWindow constructor"""

        super().__init__()
        # Main UI code goes here

        self.post_model = ModelPost()
        self.post_view = ViewPost()
        self.setLayout(qtw.QVBoxLayout())
        self.layout().addWidget(self.post_view)

        self.post_thread = qtc.QThread(parent=self)
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

        self.post_view.cancel_signal.connect(self.on_cancel)

        # End main UI code
        self.show()

    def on_started(self):
        """Statusbar update upon start"""

        self.started_post.emit('Post processing.')

    def on_cancel(self):
        """GUI termination upon cancel:
        - thread termination
        -statusbar update
        """

        self.post_thread.quit()
        self.post_thread.deleteLater()
        self.post_view.start_btn.setEnabled(True)
        self.finished_post.emit('Post processing cancelled.')

    def on_finished(self):
        """GUI preparation upon finish:
        -thread termination
        -statusbar update
        """

        self.post_thread.quit()
        self.post_model.deleteLater()
        self.post_view.start_btn.setEnabled(True)
        self.finished_post.emit('Post processing finished.')
