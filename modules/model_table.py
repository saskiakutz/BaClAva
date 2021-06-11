# Title     : Tabel model
# Objective : Table modelling for GUI model 3
# Written by: Saskia Kutz

import sys
from os import path, mkdir
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
# from Python_to_R import r_bayesian_run
# from Python_to_R import r_test
import csv
import pandas as pd


class TableModel(qtc.QAbstractTableModel):
    """Data preparation for table in Module 3"""

    def __init__(self, file):
        super().__init__()
        self.filename = file
        with open(self.filename) as fh:
            # reader = csv.reader(fh)
            # self._headers = next(reader)
            # self._data = list(reader)
            self._headers = list(pd.read_csv(self.filename, nrows=1))
            self._data = list(pd.read_csv(self.filename, skiprows=1, nrows=5))
            print(self._data)
            print(self._headers)

    def rowCount(self, parent):
        """set number of shown rows to 5"""
        # return len(self._data)
        return 5

    def columnCount(self, parent):
        return len(self._headers)

    def data(self, index, role):
        if role == qtc.Qt.DisplayRole:
            return self._data[index.row()][index.column()]

    def headerData(self, section, orientation, role):
        """header preparation for PyQT5 visualization"""
        if (
                orientation == qtc.Qt.Horizontal and
                role == qtc.Qt.DisplayRole
        ):
            return self._headers[section]
        else:
            return super().headerData(section, orientation, role)
