import sys
from os import path, mkdir
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
from Python_to_R import r_simulation


class Model(qtc.QObject):
    error = qtc.pyqtSignal(str)

    def print_income(self, inputs):
        print("save_called")

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
                dir_file = dir_ + '/' + 'sim_parameters.txt'
                list_dir = [f'{key}={inputs[key]}' for key in inputs]
                with open(dir_file, 'w') as fh:
                    [fh.write(f'{st}\n') for st in list_dir]

            except Exception as e:
                error = f'Cannot store parameters: {e}'

            r_simulation(inputs)

        # TODO: simulation
        if error:
            self.error.emit(error)
