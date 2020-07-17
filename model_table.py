import sys
from os import path, mkdir
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
from Python_to_R import r_bayesian_run
from Python_to_R import r_test
import csv


class TableModel(qtc.QAbstractTableModel):
    def __init__(self, file):
        super().__init__()
        self.filename = file
        with open(self.filename) as fh:
            reader = csv.reader(fh)
            self._headers = next(reader)
            self._data = list(reader)

    def rowCount(self, parent):
        # return len(self._data)
        return 5

    def columnCount(self, parent):
        return len(self._headers)

    def data(self, index, role):
        if role == qtc.Qt.DisplayRole:
            return self._data[index.row()][index.column()]

    def headerData(self, section, orientation, role):
        if (
                orientation == qtc.Qt.Horizontal and
                role == qtc.Qt.DisplayRole
        ):
            return self._headers[section]
        else:
            return super().headerData(section, orientation, role)
