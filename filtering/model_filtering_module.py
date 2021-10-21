# Title     : Module 4 model
# Objective : Model setup of module 4
# Written by: Saskia Kutz

from os import path
from PyQt5 import QtCore as qtc
from PyQt5 import QtWidgets as qtw


class ModuleFiltering(qtw.QWidget):

    def __init__(self):
        super().__init__()
        self.inputs = None

    def import_data(self):
        pass

    def update_plot(self):
        pass