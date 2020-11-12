import sys
from os import path, mkdir
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
from Python_to_R import PythonToR


class Model_post(qtc.QObject):
    error = qtc.pyqtSignal(str)
    finished = qtc.pyqtSignal()

    def __init__(self):
        super().__init__()
        self.inputs = None

    @qtc.pyqtSlot(object)
    def set_data(self, inputs):
        self.inputs = inputs

    @qtc.pyqtSlot()
    def check_income(self):
        print('save_connected')
        print(self.inputs)

        error = ''
        dir_ = self.inputs.get('directory')
        if dir_ == "select data directory":
            error = f'You need to choose a directory'
        elif not path.isdir(dir_.rsplit('/', 1)[0]):
            error = f'You need to choose a valid directory'
        elif not path.isdir(dir_):
            error = f'You need to choose a valid directory'
        else:
            try:
                ptor = PythonToR()
                ptor.r_post_processing(self.inputs)
            except Exception as e:
                error = f'Cannot do the post processing: {e}'

        self.finished.emit()

        if error:
            self.error.emit(error)
