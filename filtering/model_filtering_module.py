# Title     : Module 4 model
# Objective : Model setup of module 4
# Written by: Saskia Kutz

from os import path

import h5py
import numpy as np
import pandas as pd
from PyQt5 import QtCore as qtc
from PyQt5 import QtWidgets as qtw


class ModuleFiltering(qtw.QWidget):

    error = qtc.pyqtSignal(str)
    data_signal = qtc.pyqtSignal(object)

    def __init__(self):
        super().__init__()
        self.inputs = None
        self.area_update = None
        self.density_update = None
        self.dataset = None
        self.summary_table = None

    @qtc.pyqtSlot(str)
    def set_data(self, inputs):
        self.inputs = inputs

    @qtc.pyqtSlot(object)
    def set_area_density(self, updated_values):
        self.area_update, self.density_update = updated_values
        print(self.area_update)
        print(self.density_update)

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
            data, summary = self.import_data()
            self.data_signal.emit([data, summary])

        if error:
            self.error.emit(error)

    def import_data(self):

        with h5py.File(self.inputs, 'r') as f:
            label_set = f['r_vs_thresh'].attrs['best'][0].decode()
            labels = np.asarray(f['labels/' + label_set][()])
            columns_data = f['data'].attrs['datacolumns'] - 1
            columns_data = columns_data.tolist()
            self.dataset = pd.DataFrame(f['data'][()]).iloc[:, columns_data]
            self.summary_table = pd.DataFrame(f['summarytable'][()])

        labels = self.single_values(labels)
        self.dataset['labels'] = labels
        self.dataset['labels_plot'] = labels
        self.summary_table['labels'] = np.arange(self.summary_table.shape[0]) + 1

        return [self.dataset, self.summary_table]

    @staticmethod
    def single_values(cluster_labels):
        """
        function to change labels for background localisations to zero
        """

        values, counts = np.unique(cluster_labels, return_counts=True)
        count_dic = dict(zip(values, counts))
        for key, value in count_dic.items():
            if value == 1:
                cluster_labels = np.where(cluster_labels == key, 0, cluster_labels)

        return cluster_labels.astype(int)

    def data_update(self):
        pass