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


matplotlib.use('Qt5Agg')
import numpy as np
from matplotlib.backends.backend_qt5agg import (FigureCanvasQTAgg as FigureCanvas,
                                                NavigationToolbar2QT as NavigationToolbar)
from matplotlib.figure import Figure


class ViewFiltering(qtw.QWidget):
    """View part of module 4"""

    sub_data = qtc.pyqtSignal(str)
    updated_labels = qtc.pyqtSignal(object)
    batch_data = qtc.pyqtSignal(object)

    def __init__(self):
        """Setup of all GUI sections and options"""

        super().__init__()

        main_layout = qtw.QHBoxLayout()
        option_layout = qtw.QVBoxLayout()

        parameter_layout = qtw.QFormLayout()
        self.file_btn = qtw.QPushButton("Select file")
        self.file_btn.clicked.connect(self.choose_file)

        self.file_line = qtw.QLineEdit("Select file")
        self.file_line.setReadOnly(True)
        parameter_layout.addRow(self.file_btn, self.file_line)

        self.spot_label = qtw.QLabel('Spot size')
        self.spot_size = qtw.QDoubleSpinBox(
            self,
            minimum=1,
            maximum=100,
            singleStep=0.1,
            value=1
        )
        self.spot_size.valueChanged.connect(self.update_plot_point_size)
        parameter_layout.addRow(self.spot_label, self.spot_size)
        option_layout.addLayout(parameter_layout)

        slider_layout = qtw.QVBoxLayout()
        self.density_slider = Slider('Density', 0, 10)
        slider_layout.addWidget(self.density_slider)
        self.area_slider = Slider('Area', 0, 10)
        slider_layout.addWidget(self.area_slider)

        option_layout.addLayout(slider_layout)

        storage_layout = qtw.QHBoxLayout()

        self.image_btn = qtw.QPushButton("Store image")
        self.image_btn.clicked.connect(self.choose_storage_image)
        storage_layout.addWidget(self.image_btn)
        self.data_btn = qtw.QPushButton("Store data")
        self.data_btn.clicked.connect(self.choose_storage_data)
        storage_layout.addWidget(self.data_btn)

        option_layout.addLayout(storage_layout)

        batch_layout = qtw.QVBoxLayout()
        self.batch_label = qtw.QLabel('Batch processing:')
        batch_layout.addWidget(self.batch_label)
        batch_parameters_layout = qtw.QFormLayout()
        self.density_label = qtw.QLabel('Batch density')
        self.density_value = qtw.QDoubleSpinBox(
            self,
            minimum=1,
            maximum=100000,
            singleStep=0.1,
            value=1
        )
        self.area_label = qtw.QLabel('Batch area')
        self.area_value = qtw.QDoubleSpinBox(
            self,
            minimum=1,
            maximum=100000,
            singleStep=0.1,
            value=1
        )
        self.data_image_btn = qtw.QPushButton('Store data and images')
        self.data_image_btn.clicked.connect(self.choose_storage_data_image)
        self.only_image_btn = qtw.QPushButton('Store images only')
        self.only_image_btn.clicked.connect(self.choose_storage_image_only)
        batch_parameters_layout.addRow(self.density_label, self.density_value)
        batch_parameters_layout.addRow(self.area_label, self.area_value)
        batch_parameters_layout.addRow(self.data_image_btn, self.only_image_btn)
        batch_layout.addLayout(batch_parameters_layout)

        option_layout.addLayout(batch_layout)

        plot_layout = qtw.QVBoxLayout()

        self.plot_window = MplCanvas(self, width=5, height=5, dpi=200)
        plot_layout.addWidget(self.plot_window)

        self.plot_toolbar = NavigationToolbar(self.plot_window, self)
        plot_layout.addWidget(self.plot_toolbar)

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

        self.data_df, self.summary_df = data_signal

        self.update_sliders()

        self.plot_window.axes.cla()
        self.draw_scatterplot(self.data_df, self.plot_window, 'x [nm]', 'y [nm]')

    def update_plot_point_size(self):
        self.plot_window.axes.cla()
        self.draw_scatterplot(self.data_df, self.plot_window, 'x [nm]', 'y [nm]')

    def draw_scatterplot(self, data_scatter, canvas, x_label, y_label):
        """Scatter plot of a clustering result"""

        canvas.axes.cla()
        size_pt = (2 * self.spot_size.value() / canvas.fig.dpi * 72) ** 2
        canvas.axes.scatter(x=data_scatter.iloc[:, 0], y=data_scatter.iloc[:, 1], s=0, clip_on=False)
        canvas.axes.set_ylabel(y_label, fontsize='10')
        canvas.axes.set_xlabel(x_label, fontsize='10')
        canvas.draw()
        colour = self.scatterplot_colour(data_scatter.iloc[:, -1])
        canvas.axes.scatter(x=data_scatter.iloc[:, 0], y=data_scatter.iloc[:, 1], s=size_pt, color=colour, alpha=0.9,
                            edgecolors="none")

        canvas.draw()

    def scatterplot_colour(self, labels):
        """colour selection for the scatter plot:
        - clusters in colour
        - background localizations: silver
        """

        unique_labels = np.unique(labels)
        number_unique_labels = len(unique_labels)
        temp_labels = labels.copy()
        for i in range(1, len(unique_labels)):
            temp_labels[temp_labels == unique_labels[i]] = i

        if number_unique_labels > 1:
            colors = sns.color_palette("CMRmap_r", n_colors=number_unique_labels - 1)
        else:
            colors = sns.color_palette("CMRmap_r", n_colors=number_unique_labels)
        scale = ['silver' if label == 0 else colors[label-1] for label in temp_labels]
        return scale

    def update_labels(self):

        updated_area_density = [self.area_slider.x, self.density_slider.x]
        self.density_value.setValue(self.density_slider.x)
        self.area_value.setValue(self.area_slider.x)
        self.updated_labels.emit(updated_area_density)

    def update_sliders(self):

        area_max = self.summary_df.iloc[:, 1].max() * 1000 + 1
        area_min = self.summary_df.iloc[:, 1].min() * 1000 -1
        density_max = self.summary_df.iloc[:, 2].max() + 1
        density_min = self.summary_df.iloc[:, 2]. min() -1

        self.area_slider.update_min_max(area_min, area_max)
        self.density_slider.update_min_max(density_min, density_max)

    def choose_storage_image(self):

        filename, ending = qtw.QFileDialog.getSaveFileName(
            self,
            "Save Image",
            os.path.dirname(self.file_line.text()),
            'png image (*.png);; tiff image (*.tiff)'
        )
        if ending == 'png image (*.png)':
            self.plot_window.print_png(filename)

        else:
            self.plot_window.print_tiff(filename)

    def choose_storage_data(self):
        filename, _ = qtw.QFileDialog.getSaveFileName(
            self,
            "Save Image",
            os.path.dirname(self.file_line.text()),
            'csv file (*.csv);; txt file (*.txt)'
        )

        self.data_df.loc[:, self.data_df.columns != 'labels'].to_csv(filename)

    def choose_storage_image_only(self):
        pass

    def choose_storage_data_image(self):

        directory_path = os.path.dirname(self.file_line.text())
        self.batch_data.emit([directory_path, self.density_value.value(), self.area_value.value()])

    def show_error(self, error):
        """error message in separate window"""

        qtw.QMessageBox.critical(None, 'Error', error)
