# Title     : Module 4 view
# Objective : View setup of module 4
# Written by: Saskia Kutz

from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
import os
import matplotlib
import random
import pandas as pd
import seaborn as sns
import h5py
from filtering.model_slider import Slider

import pyqtgraph as pg

matplotlib.use('Qt5Agg')
import numpy as np
from matplotlib.backends.backend_qt5agg import (FigureCanvasQTAgg as FigureCanvas,
                                                NavigationToolbar2QT as NavigationToolbar)
from matplotlib.figure import Figure


class ViewFiltering(qtw.QWidget):
    """View part of module 4"""

    def __init__(self):
        """Setup of all GUI sections and options"""

        super().__init__()

        main_layout = qtw.QHBoxLayout()
        option_layout = qtw.QVBoxLayout()

        parameter_layout = qtw.QHBoxLayout()

        self.file_btn = qtw.QPushButton("Select file")
        self.file_btn.clicked.connect(self.choose_file)
        parameter_layout.addWidget(self.file_btn)
        self.file_line = qtw.QLineEdit("Select file")
        self.file_line.setReadOnly(True)
        parameter_layout.addWidget(self.file_line)

        option_layout.addLayout(parameter_layout)

        slider_layout = qtw.QVBoxLayout()
        self.density_slider = Slider('Density', -10, 10)
        slider_layout.addWidget(self.density_slider)
        self.area_slider = Slider('Area', -10, 10)
        slider_layout.addWidget(self.area_slider)

        option_layout.addLayout(slider_layout)

        storage_layout = qtw.QHBoxLayout()

        self.image_btn = qtw.QPushButton("Store image")
        self.image_btn.clicked.connect(self.choose_storage)
        storage_layout.addWidget(self.image_btn)
        self.data_btn = qtw.QPushButton("Store data")
        self.data_btn.clicked.connect(self.choose_storage)
        storage_layout.addWidget(self.data_btn)

        option_layout.addLayout(storage_layout)

        plot_layout = qtw.QVBoxLayout()

        self.plot_window = pg.GraphicsWindow(title='Plotting test')
        plot_layout.addWidget(self.plot_window)
        self.plotting = self.plot_window.addPlot(title='plot')
        self.plot = self.plotting.plot(pen='r')
        self.update_plot()

        main_layout.addLayout(option_layout)
        main_layout.addLayout(plot_layout)


        # show final layout
        self.setLayout(main_layout)

    def choose_file(self):

        filename, _ = qtw.QFileDialog.getOpenFileName(
            self,
            "Select data file",
            qtc.QDir.homePath(),
            'hdf5 files (*.h5)'
        )
        self.file_line.setText(filename)

    def update_plot(self):
        pass

    def choose_storage(self):
        pass