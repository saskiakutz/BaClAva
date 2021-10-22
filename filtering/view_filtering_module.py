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
from post.view_post_module import MplCanvas

import pyqtgraph as pg

matplotlib.use('Qt5Agg')
import numpy as np
from matplotlib.backends.backend_qt5agg import (FigureCanvasQTAgg as FigureCanvas,
                                                NavigationToolbar2QT as NavigationToolbar)
from matplotlib.figure import Figure


class ViewFiltering(qtw.QWidget):
    """View part of module 4"""

    sub_data = qtc.pyqtSignal(str)
    updated_labels = qtc.pyqtSignal(object)

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

        self.plot_window = MplCanvas(self, width=5, height=5, dpi=200)
        plot_layout.addWidget(self.plot_window)

        self.area_slider.slider.valueChanged.connect(self.update_labels)
        self.density_slider.slider.valueChanged.connect(self.update_labels)

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

        self.sub_data.emit(filename)

    def update_plot(self, data_signal):

        data_df, summary_df = data_signal

        self.plot_window.axes.cla()
        self.draw_scatterplot(data_df, self.plot_window, 'x [nm]', 'y [nm]')

    def draw_scatterplot(self, data_scatter, canvas, x_label, y_label):
        """Scatterplot of a clustering result"""

        canvas.axes.cla()
        canvas.axes.scatter(x=data_scatter.iloc[:, 0], y=data_scatter.iloc[:, 1], s=0, clip_on=False)
        canvas.axes.set_ylabel(y_label, fontsize='10')
        canvas.axes.set_xlabel(x_label, fontsize='10')
        canvas.draw()

        colour = self.scatterplot_colour(data_scatter.iloc[:, -1])
        canvas.axes.scatter(x=data_scatter.iloc[:, 0], y=data_scatter.iloc[:, 1], color=colour, alpha=0.9,
                            edgecolors="none")

        canvas.draw()

    def scatterplot_colour(self, labels):
        """colour selection for the scatter plot:
        - clusters in colour
        - background localizations: silver
        """

        colors = sns.color_palette("CMRmap_r", n_colors=len(np.unique(labels)) - 1)
        scale = ['silver' if label == 0 else colors[label - 1] for label in labels]
        return scale

    def update_labels(self):

        updated_area_density = [self.area_slider.x, self.density_slider.x]
        self.updated_labels.emit(updated_area_density)

    def choose_storage(self):
        pass

    def show_error(self, error):
        """error message in separate window"""

        qtw.QMessageBox.critical(None, 'Error', error)
