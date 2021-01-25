import sys
from os import path, mkdir
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
# from Python_to_R import r_bayesian_run
# from Python_to_R import r_test
import csv
import h5py
import pandas as pd


class DataFrameModel(qtc.QAbstractTableModel):
    DtypeRole = qtc.Qt.UserRole + 1000
    ValueRole = qtc.Qt.UserRole + 1001

    def __init__(self, file, parent=None):
        super(DataFrameModel, self).__init__(parent)
        if file.split(".")[1] == "txt" or file.split(".")[1] == "csv":
            self._dataframe = pd.read_csv(file, nrows=5)
        else:
            with h5py.File(file, "r") as f:
                print("Keys: %s" % f.keys())
                for key in f.keys():
                    if key not in {'labels', 'r_vs_thresh'}:
                        a_group_key = key
                        break
                print(a_group_key)
                self._dataframe = pd.DataFrame(f[a_group_key][1:6])

    def setDataFrame(self, dataframe):
        self.beginResetModel()
        self._dataframe = dataframe.copy()
        self.endResetModel()

    def dataFrame(self):
        return self._dataframe

    dataFrame = qtc.pyqtProperty(pd.DataFrame, fget=dataFrame, fset=setDataFrame)

    @qtc.pyqtSlot(int, qtc.Qt.Orientation, result=str)
    def headerData(self, section: int, orientation: qtc.Qt.Orientation, role: int = qtc.Qt.DisplayRole):
        if role == qtc.Qt.DisplayRole:
            if orientation == qtc.Qt.Horizontal:
                return self._dataframe.columns[section]
            else:
                return str(self._dataframe.index[section])
        return qtc.QVariant()

    def rowCount(self, parent=qtc.QModelIndex()):
        if parent.isValid():
            return 0
        return len(self._dataframe.index)

    def columnCount(self, parent=qtc.QModelIndex()):
        if parent.isValid():
            return 0
        return self._dataframe.columns.size

    def data(self, index, role=qtc.Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < self.rowCount() and 0 <= index.column() < self.columnCount()):
            return qtc.QVariant()
        row = self._dataframe.index[index.row()]
        col = self._dataframe.columns[index.column()]
        dt = self._dataframe[col].dtype

        val = self._dataframe.iloc[row][col]
        if role == qtc.Qt.DisplayRole:
            return str(val)
        elif role == DataFrameModel.ValueRole:
            return val
        if role == DataFrameModel.DtypeRole:
            return dt
        return qtc.QVariant()

    def roleNames(self):
        roles = {
            qtc.Qt.DisplayRole: b'display',
            DataFrameModel.DtypeRole: b'dtype',
            DataFrameModel.ValueRole: b'value'
        }
        return roles
