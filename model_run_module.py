import sys
from os import path, mkdir
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
from Python_to_R import r_bayesian_run


class Model_run(qtc.QObject):
    error = qtc.pyqtSignal(str)

    def check_income(self, inputs, parallel):
        print('save_connected')
        print(inputs)
        print(parallel)

        error = ''
        dir_ = inputs.get('directory')

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
                list_dir = [f'{key}={inputs[key]}' for key in inputs]
                par_dir = [f'{key}={parallel[key]}' for key in parallel]
                with open(dir_file, 'w') as fh:
                    [fh.write(f'{st}\n') for st in list_dir]
                    [fh.write(f'{st}\n') for st in par_dir]

            except Exception as e:
                error = f'Cannot store parameters: {e}'

            try:
                r_bayesian_run(inputs, parallel)

            except Exception as e:
                error = f'Cannot do the Bayesian analysis: {e}'

        if error:
            self.error.emit(error)
