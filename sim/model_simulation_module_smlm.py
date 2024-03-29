# Title     : Model for module 1b
# Objective : Model setup of module 1b
# Written by: Saskia Kutz

from os import path, mkdir
from PyQt5 import QtCore as qtc
from pythonr.Python_to_R import PythonToR


class ModelSMLM(qtc.QObject):
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
    def print_income(self):
        """check for correct directory and connection to R"""

        print("save_called")

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
                dir_file = dir_ + '/' + 'sim_smlm_parameters.txt'
                list_dir = [f'{key}={self.inputs[key]}' for key in self.inputs]
                with open(dir_file, 'w') as fh:
                    [fh.write(f'{st}\n') for st in list_dir]

            except Exception as e:
                error = f'Cannot store parameters: {e}'

            try:
                simulation = PythonToR()
                simulation.r_smlm_simulation(self.inputs)

            except Exception as e:
                error = f'Cannot do the simulations: {e}'

        self.finished.emit()

        if error:
            self.error.emit(error)
