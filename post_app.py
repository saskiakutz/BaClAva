import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc

from view_post_module import View_post
from model_post_module import Model_post


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

        self.setWindowTitle("Post Processing 1.0")
        self.post_model = Model_post()
        self.post_view = View_post()
        self.setCentralWidget(self.post_view)

        self.post_thread = qtc.QThread()
        self.post_model.moveToThread(self.post_thread)
        self.post_model.finished.connect(self.post_thread.quit)
        self.post_thread.start()

        self.post_view.submitted.connect(self.post_model.set_data)
        self.post_view.startpost.connect(self.post_thread.start)
        self.post_view.submitted.connect(self.post_model.check_income)
        self.post_model.error.connect(self.post_view.show_error)

        self.post_model.finished.connect(self.on_finished)
        self.post_model.finished.connect(self.post_view.show_data)

        status_bar = qtw.QStatusBar()
        self.setStatusBar(status_bar)
        status_bar.showMessage('Post processing')
        # TODO: status_bar update messages

        # End main UI code
        self.show()

    def on_finished(self):
        self.statusBar().showMessage('Post processing finished')
        self.post_view.start_btn.setEnabled(True)


if __name__ == '__main__':
    app = qtw.QApplication(sys.argv)
    mw = MainWindow()
    sys.exit(app.exec())
