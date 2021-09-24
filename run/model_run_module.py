# Title     : Model for module 2
# Objective : Model setup of module 2
# Written by: Saskia Kutz

from os import path, mkdir, listdir
from PyQt5 import QtCore as qtc
from pythonr.Python_to_R import PythonToR


class ModelRun(qtc.QObject):
    """Data check for R backbone"""

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
        """check for correct directory and connection to R"""

        print('save_connected')
        print(self.inputs, self.parallel)

        error = ''
        dir_ = self.inputs.get('directory')
        source_ = self.inputs.get('datasource')

        if dir_ == "select data directory":
            error = f'You need to choose a directory'
        elif not path.isdir(dir_.rsplit('/', 1)[0]):
            error = f'You need to choose a valid directory'
        elif not path.isdir(dir_):
            try:
                mkdir(dir_)
            except Exception as e:
                error = f'Directory creation failed'
        elif (source_ == 'simulation') and (not any(f_name.endswith('.h5') for f_name in listdir(dir_))):
            error = f'There is not any hdf5 in your directory'
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
                ptor = PythonToR()
                if source_ == 'experiment':
                    ptor.check_dataset_type(dir_)
                ptor.r_bayesian_run(self.inputs, self.parallel)

            except Exception as e:
                error = f'Cannot do the Bayesian analysis: {e}'

        self.finished.emit()

        if error:
            self.error.emit(error)
