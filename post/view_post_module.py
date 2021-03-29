from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
import os
import matplotlib
import random
import pandas as pd
import seaborn as sns
import h5py

matplotlib.use('Qt5Agg')
import numpy as np
from matplotlib.backends.backend_qt5agg import (FigureCanvasQTAgg as FigureCanvas,
                                                NavigationToolbar2QT as NavigationToolbar)
from matplotlib.figure import Figure


class MplCanvas(FigureCanvas):
    def __init__(self, parent=None, width=5, height=5, dpi=100):
        self.fig = Figure(figsize=(width, height), dpi=dpi, tight_layout=True)
        self.axes = self.fig.add_subplot(111)
        super(MplCanvas, self).__init__(self.fig)

        FigureCanvas.setMinimumSize(self, 100, 185)
        FigureCanvas.setSizePolicy(self,
                                   qtw.QSizePolicy.MinimumExpanding,
                                   qtw.QSizePolicy.MinimumExpanding)
        FigureCanvas.updateGeometry(self)


class View_post(qtw.QWidget):
    submitted = qtc.pyqtSignal(object)
    startpost = qtc.pyqtSignal()
    cancel_signal = qtc.pyqtSignal()

    # noinspection PyArgumentList
    def __init__(self):
        super().__init__()

        main_layout = qtw.QVBoxLayout()

        parameter_layout = qtw.QFormLayout()
        # heading = qtw.QLabel("Post Processing")
        # parameter_layout.addRow(heading)
        # heading_font = qtg.QFont('Arial', 32, qtg.QFont.Bold)
        # heading_font.setStretch(qtg.QFont.ExtraExpanded)
        # heading.setFont(heading_font)

        self.dir_btn = qtw.QPushButton("Select data directory")
        self.dir_btn.clicked.connect(self.choose_file)
        self.dir_line = qtw.QLineEdit("select data directory")
        self.dir_line.setReadOnly(True)
        self.dir_line.textChanged.connect(lambda x: self.dir_line.setReadOnly(x == ''))

        parameter_layout.addRow(self.dir_btn, self.dir_line)

        self.p_inputs = {
            # "datasource": qtw.QComboBox(),
            # "Bayesian computation": qtw.QComboBox(),
            "store plots": qtw.QCheckBox(),
            "superplot": qtw.QCheckBox(),
            "separate plots": qtw.QCheckBox()
        }

        # datasource = ('simulation', 'experiment')
        # self.p_inputs["datasource"].addItems(datasource)

        # computation = ('sequential', 'parallel')
        # self.p_inputs["Bayesian computation"].addItems(computation)

        self.p_inputs["superplot"].setDisabled(True)
        self.p_inputs["separate plots"].setDisabled(True)
        self.p_inputs["store plots"].toggled.connect(self.p_inputs["superplot"].setEnabled)
        self.p_inputs["store plots"].toggled.connect(self.p_inputs["separate plots"].setEnabled)
        # self.p_inputs["store plots"].toggled.connect(self.change_plot_options)
        # self.p_inputs["datasource"].currentIndexChanged.connect(self.change_plot_options)

        for label, widget in self.p_inputs.items():
            parameter_layout.addRow(label, widget)

        main_layout.addLayout(parameter_layout)

        button_layout = qtw.QHBoxLayout()

        self.start_btn = qtw.QPushButton(
            "start",
            clicked=self.start_post
        )
        self.start_btn.setDisabled(True)
        self.dir_line.textChanged.connect(lambda x: self.start_btn.setDisabled(x == ''))
        self.cancel_btn = qtw.QPushButton(
            "cancel",
            clicked=self.cancel_signal.emit
        )

        button_layout.addWidget(self.start_btn)
        button_layout.addWidget(self.cancel_btn)
        main_layout.addLayout(button_layout)

        # plot_layout = qtw.QVBoxLayout()
        plot_layout = qtw.QGridLayout()

        # area_number_layout = qtw.QHBoxLayout()
        # percentage_ratio_layout = qtw.QHBoxLayout()
        # plot_layout.addLayout(area_number_layout)
        # plot_layout.addLayout(percentage_ratio_layout)

        # self.text = qtw.QLabel('cluster plot')
        # plot_layout.addWidget(self.text, 1, 0)
        self.scatter_canvas = MplCanvas(self, width=5, height=6, dpi=100)
        scatter_tb = NavigationToolbar(self.scatter_canvas, self)
        plot_layout.addWidget(scatter_tb, 0, 0)
        plot_layout.addWidget(self.scatter_canvas, 1, 0)

        self.area_canvas = MplCanvas(self, width=5, height=6, dpi=100)
        # area_number_layout.addWidget(self.area_canvas)
        area_tb = NavigationToolbar(self.area_canvas, self)
        plot_layout.addWidget(area_tb, 0, 1)
        plot_layout.addWidget(self.area_canvas, 1, 1)

        self.number_canvas = MplCanvas(self, width=5, height=6, dpi=100)
        # area_number_layout.addWidget(self.number_canvas)
        number_tb = NavigationToolbar(self.number_canvas, self)
        plot_layout.addWidget(number_tb, 0, 2)
        plot_layout.addWidget(self.number_canvas, 1, 2)

        self.density_canvas = MplCanvas(self, width=5, height=5, dpi=100)
        density_tb = NavigationToolbar(self.density_canvas, self)
        plot_layout.addWidget(density_tb, 2, 0)
        plot_layout.addWidget(self.density_canvas, 3, 0)

        self.percentage_canvas = MplCanvas(self, width=5, height=6, dpi=100)
        # percentage_ratio_layout.addWidget(self.percentage_canvas)
        percentage_tb = NavigationToolbar(self.percentage_canvas, self)
        plot_layout.addWidget(percentage_tb, 2, 1)
        plot_layout.addWidget(self.percentage_canvas, 3, 1)

        self.ratio_canvas = MplCanvas(self, width=5, height=6, dpi=100)
        # percentage_ratio_layout.addWidget(self.ratio_canvas)
        ratio_tb = NavigationToolbar(self.ratio_canvas, self)
        plot_layout.addWidget(ratio_tb, 2, 2)
        plot_layout.addWidget(self.ratio_canvas, 3, 2)

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
        self.dir_line.setText(os.path.dirname(filename))

    # def change_plot_options(self):
    #     if self.p_inputs["datasource"].currentText() == "simulation" and self.p_inputs["store plots"].isChecked():
    #         self.p_inputs["separate plots"].setEnabled(True)
    #         self.p_inputs["separate plots"].setChecked(False)
    #
    #     elif self.p_inputs["datasource"].currentText() == "experiment" and self.p_inputs["store plots"].isChecked():
    #         self.p_inputs["separate plots"].setChecked(True)
    #
    #     else:
    #         self.p_inputs["separate plots"].setDisabled(True)
    #         self.p_inputs["separate plots"].setChecked(False)
    #         self.p_inputs["superplot"].setChecked(False)

    def start_post(self):
        data = {
            'directory': self.dir_line.text(),
            # 'datasource': self.p_inputs["datasource"].currentText(),
            # 'computation': self.p_inputs["Bayesian computation"].currentText(),
            'storeplots': self.p_inputs["store plots"].isChecked(),
            'superplot': self.p_inputs["superplot"].isChecked(),
            'separateplots': self.p_inputs["separate plots"].isChecked()
        }

        self.start_btn.setDisabled(True)
        self.startpost.emit()
        self.submitted.emit(data)

    def show_error(self, error):
        qtw.QMessageBox.critical(None, 'Error', error)

    def show_data(self):
        self.area_canvas.axes.cla()
        self.draw_scatterplot(self.scatter_canvas, 'x [µm]', 'y [µm]')
        self.draw_hist(self.area_canvas, 'area', 'cluster area [µm²]', 'number of clusters')
        self.draw_hist(self.number_canvas, 'nclusters', 'number of cluster', 'number of regions')
        self.draw_hist(self.density_canvas, 'density', 'cluster density [µm⁻²]', 'number of clusters')
        self.draw_hist(self.percentage_canvas, 'pclustered', 'percentage clustered',
                       'number of regions')
        self.draw_hist(self.ratio_canvas, 'reldensity', 'relative density clusters/background',
                       'number of regions')

    def draw_hist(self, canvas, data_type, x_label, y_label):

        canvas.axes.cla()
        data_in = self.import_postdata(data_type)
        # data_ax = canvas.figure.subplots()

        if len(data_in) > 1:
            bw = 2 * np.subtract.reduce(np.percentile(data_in, [75, 25])) / len(data_in) ** (1 / 3)
            if bw == 0:
                bw = 1
            canvas.axes.hist(data_in, bins=np.arange(min(data_in), max(data_in) + bw, bw))
        else:
            canvas.axes.hist(data_in, bins=1)
        canvas.axes.set_ylabel(y_label, fontsize='10')
        canvas.axes.set_xlabel(x_label, fontsize='10')
        canvas.draw()

    def import_postdata(self, info_type):
        data_dir = self.dir_line.text() + "/postprocessing/" + info_type + ".txt"
        with open(data_dir, 'r') as file_in:
            x = [float(y) for y in file_in.read().split(",")]
        return x

    def draw_scatterplot(self, canvas, x_label, y_label):

        canvas.axes.cla()
        data_scatter = self.import_scatterdata()

        canvas.axes.scatter(x=data_scatter['x'], y=data_scatter['y'], s=0, clip_on=False)
        canvas.axes.set_ylabel(y_label, fontsize='10')
        canvas.axes.set_xlabel(x_label, fontsize='10')
        canvas.draw()

        # Calculate radius in pixels :
        rr_pix = (canvas.axes.transData.transform(np.vstack([data_scatter['sd'], data_scatter['sd']]).T) -
                  canvas.axes.transData.transform(
                      np.vstack([np.zeros(len(data_scatter)), np.zeros(len(data_scatter))]).T))
        rpix, _ = rr_pix.T

        # Calculate and update size in points:
        size_pt = (2 * rpix / canvas.fig.dpi * 72) ** 2
        colour = self.scatterplot_colour((data_scatter['labels']))
        canvas.axes.scatter(x=data_scatter['x'], y=data_scatter['y'], s=size_pt, color=colour, alpha=0.9,
                            edgecolors="none")

        canvas.draw()

    def scatterplot_colour(self, labels):
        label_counts = labels.value_counts()
        cnames = label_counts[label_counts > 1]
        colors = sns.color_palette("CMRmap_r", n_colors=len(cnames))
        scale = ['silver' if label_counts[label] == 1 else colors[label - 1] for label in labels]
        return scale

    def import_scatterdata_old(self):
        names = ["summary.txt", "labels", "data.txt"]
        folder_list = [name for name in os.listdir(self.dir_line.text() + "/") if
                       os.path.isdir(self.dir_line.text() + "/" + name) and name != 'postprocessing']

        folder_os = os.path.join(self.dir_line.text(), random.choice(folder_list))

        file_os = os.path.join(folder_os, names[0])
        with open(file_os, 'r') as file_in:
            best_label = file_in.readline().strip().split(": ")[1]

        labels_os = os.path.join(folder_os, names[1], best_label)
        with open(labels_os, 'r') as file_in:
            cluster_labels = [int(lab) for lab in file_in.read().split(",")]

        data_os = os.path.join(folder_os, names[2])
        data = pd.read_csv(data_os, sep=',', header=0, usecols=["x", "y", "sd"])
        data = data.divide(1000)
        data["labels"] = cluster_labels

        return data

    def import_scatterdata(self):
        datalist = [name for name in os.listdir(self.dir_line.text()) if
                    os.path.isfile(os.path.join(self.dir_line.text(), name)) and name.endswith('.h5')]

        data_os = os.path.join(self.dir_line.text(), random.choice(datalist))
        with h5py.File(data_os, 'r') as f:
            labelset = f['r_vs_thresh'].attrs['best'][0].decode()
            labels = pd.array(f['labels/' + labelset][()]).astype(int)
            columns = f['data'].attrs['datacolumns'] - 1
            columns = columns.tolist()
            dataset = pd.DataFrame(f['data'][()]).iloc[:, columns]
        dataset = dataset.divide(1000)
        dataset['labels'] = labels

        return dataset

        # TODO: extract information
        # TODO: implement a way to rotate over all datafiles

    # TODO: import option for stored config file