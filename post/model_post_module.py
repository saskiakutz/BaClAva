# Title     : Module 3 model
# Objective : Model view of module 3
# Written by: Saskia Kutz

from os import path
from PyQt5 import QtCore as qtc
from pythonr.Python_to_R import PythonToR


class ModelPost(qtc.QObject):
    """Data check for R backbone"""

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
        """check for correct directory and connection to R"""
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
