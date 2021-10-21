# Title     : Module 4 model
# Objective : Model setup of module 4
# Written by: Saskia Kutz

from os import path
from PyQt5 import QtCore as qtc
from PyQt5 import QtWidgets as qtw


class ModuleFiltering(qtw.QWidget):

    error = qtc.pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self.inputs = None

    @qtc.pyqtSlot(object)
    def set_data(self, inputs):
        self.inputs = inputs

    def import_data(self):
        pass

    def update_plot(self):
        pass