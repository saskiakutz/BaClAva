# Title     : Module 4 model
# Objective : Model setup of module 4
# Written by: Saskia Kutz

from os import path

import h5py
import pandas as pd
from PyQt5 import QtCore as qtc
from PyQt5 import QtWidgets as qtw


class ModuleFiltering(qtw.QWidget):

    error = qtc.pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self.inputs = None

    @qtc.pyqtSlot(str)
    def set_data(self, inputs):
        self.inputs = inputs

    @qtc.pyqtSlot()
    def print_income(self):
        """check for correct directory and connection to R"""

        print("save_called")

        error = ''
        dir_ = self.inputs

        if dir_ == "Select file":
            error = f'You need to choose a file'
        elif not path.isdir(dir_.rsplit('/', 1)[0]):
            error = f'You need to choose a valid directory'
        else:
            self.import_data()

        if error:
            self.error.emit(error)

        print("all seems fine.")

    def import_data(self):

        with h5py.File(self.inputs, 'r') as f:
            label_set = f['r_vs_thresh'].attrs['best'][0].decode()
            labels = pd.array(f['labels/' + label_set][()]).astype(int)
            columns_data = f['data'].attrs['datacolumns'] - 1
            columns_data = columns_data.tolist()
            dataset = pd.DataFrame(f['data'][()]).iloc[:, columns_data]
            summary_table = pd.DataFrame(f['summarytable'][()])
        dataset['labels'] = labels
        print(summary_table)


    def update_plot(self):
        pass