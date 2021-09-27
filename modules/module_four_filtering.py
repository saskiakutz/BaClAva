# Title     : Module 4
# Objective : Connections GUI module 4
# Written by: Saskia Kutz

import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc

from filtering.view_filtering_module import ViewFiltering
# from post.model_post_module import ModelPost


class MainWindowFiltering(qtw.QWidget):
    """Connecting GUI to module 4"""

    def __init__(self):
        """MainWindow constructor"""
        super().__init__()
        # Main UI code goes here

        self.filtering_view = ViewFiltering()
        self.setLayout(qtw.QVBoxLayout())
        self.layout().addWidget(self.filtering_view)

        # End main UI code
        self.show()