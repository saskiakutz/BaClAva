import sys
from os import path, mkdir
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
from Python_to_R import PythonToR


class Model_run(qtc.QObject):
    error = qtc.pyqtSignal(str)
    finished = qtc.pyqtSignal()

    def __init__(self):
        super().__init__()
        self.inputs = None
        self.parallel = None

    @qtc.pyqtSlot(object, object)
    def set_data(self, inputs, parallel):
        self.inputs = inputs
        self.parallel = parallel

    @qtc.pyqtSlot()
    def check_income(self):
        print('save_connected')
        print(self.inputs, self.parallel)

        error = ''
        dir_ = self.inputs.get('directory')

        if dir_ == "select directory":
            error = f'You need to choose a directory'
        elif not path.isdir(dir_.rsplit('/', 1)[0]):
            error = f'You need to choose a valid directory'
        elif not path.isdir(dir_):
            try:
                mkdir(dir_)
            except Exception as e:
                error = f'Directory creation failed'
        else:
            try:
                dir_file = dir_ + '/' + 'run_config.txt'
                list_dir = [f'{key}={self.inputs[key]}' for key in self.inputs]
                par_dir = [f'{key}={self.parallel[key]}' for key in self.parallel]
                with open(dir_file, 'w') as fh:
                    [fh.write(f'{st}\n') for st in list_dir]
                    [fh.write(f'{st}\n') for st in par_dir]

            except Exception as e:
                error = f'Cannot store parameters: {e}'

            try:
                test = PythonToR()
                test.r_bayesian_run(self.inputs, self.parallel)

                # test.r_test(inputs)

            except Exception as e:
                error = f'Cannot do the Bayesian analysis: {e}'

        self.finished.emit()

        if error:
            self.error.emit(error)
