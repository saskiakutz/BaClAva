# Title     : Module 4
# Objective : Connections GUI module 4
# Written by: Saskia Kutz

import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from filtering.view_filtering_module import ViewFiltering
from filtering.model_filtering_module import ModuleFiltering


class MainWindowFiltering(qtw.QWidget):
    """Connecting GUI to module 4"""

    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here

        self.filtering_view = ViewFiltering()
        self.filtering_model = ModuleFiltering()
        self.setLayout(qtw.QVBoxLayout())
        self.layout().addWidget(self.filtering_view)

        self.filtering_view.sub_data.connect(self.filtering_model.set_data)


        # End main UI code
        self.show()