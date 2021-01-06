from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
import os
import matplotlib
import random

matplotlib.use('Qt5Agg')
import numpy as np
from matplotlib.backends.backend_qt5agg import (FigureCanvasQTAgg as FigureCanvas,
                                                NavigationToolbar2QT as NavigationToolbar)
from matplotlib.figure import Figure


class MplCanvas(FigureCanvas):
    def __init__(self, parent=None, width=5, height=5, dpi=100):
        fig = Figure(figsize=(width, height), dpi=dpi)
        self.axes = fig.add_subplot(111)
        super(MplCanvas, self).__init__(fig)

        FigureCanvas.setMinimumSize(self, 200, 370)
        FigureCanvas.setSizePolicy(self,
                                   qtw.QSizePolicy.MinimumExpanding,
                                   qtw.QSizePolicy.MinimumExpanding)
        FigureCanvas.updateGeometry(self)


class View_post(qtw.QWidget):
    submitted = qtc.pyqtSignal(object)
    startpost = qtc.pyqtSignal()

    # noinspection PyArgumentList
    def __init__(self):
        super().__init__()

        main_layout = qtw.QVBoxLayout()

        parameter_layout = qtw.QFormLayout()
        heading = qtw.QLabel("Post Processing")
        parameter_layout.addRow(heading)
        heading_font = qtg.QFont('Arial', 32, qtg.QFont.Bold)
        heading_font.setStretch(qtg.QFont.ExtraExpanded)
        heading.setFont(heading_font)

        self.dir_btn = qtw.QPushButton("Select data directory")
        self.dir_btn.clicked.connect(self.chooseFile)
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
            "cancel"  # TODO: cancel action
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

        self.text = qtw.QLabel('cluster plot')
        plot_layout.addWidget(self.text, 1, 0)

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

    def chooseFile(self):
        filename, _ = qtw.QFileDialog.getOpenFileName(
            self,
            "Select data file",
            qtc.QDir.homePath(),
            'txt files (*.txt)'
        )
        self.dir_line.setText(os.path.dirname(os.path.dirname(filename)))

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
        self.show_pixmap()
        self.draw_data(self.area_canvas, 'area', 'cluster area [µm²]', 'number of clusters')
        self.draw_data(self.number_canvas, 'nclusters', 'number of cluster', 'number of regions')
        self.draw_data(self.density_canvas, 'density', 'cluster density [µm⁻²]', 'number of clusters')
        self.draw_data(self.percentage_canvas, 'pclustered', 'percentage clustered',
                       'number of regions')
        self.draw_data(self.ratio_canvas, 'reldensity', 'relative density clusters/background',
                       'number of regions')

    def draw_data(self, canvas, data_type, x_label, y_label):

        canvas.axes.cla()
        data_in = self.import_data(data_type)
        # data_ax = canvas.figure.subplots()

        if len(data_in) > 1:
            bw = 2 * np.subtract.reduce(np.percentile(data_in, [75, 25])) / len(data_in) ** (1 / 3)
            canvas.axes.hist(data_in, bins=np.arange(min(data_in), max(data_in) + bw, bw))
        else:
            canvas.axes.hist(data_in, bins=1)
        canvas.axes.set_ylabel(y_label, fontsize='10')
        canvas.axes.set_xlabel(x_label, fontsize='10')
        canvas.draw()

    def import_data(self, info_type):
        data_dir = self.dir_line.text() + "/postprocessing/" + info_type + ".txt"
        with open(data_dir, 'r') as file_in:
            x = [float(y) for y in file_in.read().split(",")]
        return x

    def show_pixmap(self):
        folder_list = [name for name in os.listdir(self.dir_line.text() + "/") if
                       os.path.isdir(self.dir_line.text() + "/" + name) and name != 'postprocessing']
        folder_os = self.dir_line.text() + "/" + random.choice(folder_list)
        file_name = [f for f in os.listdir(folder_os) if f.endswith('.png')]
        pixmap = qtg.QPixmap(folder_os + "/" + file_name[0])
        pixmap1 = pixmap.scaled(370, 370, qtc.Qt.KeepAspectRatioByExpanding)
        self.text.setPixmap(pixmap1)
        # self.text.resize(pixmap.width(), pixmap.height())

    # TODO: import option for stored config file
