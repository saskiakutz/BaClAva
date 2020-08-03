import sys
from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from PyQt5 import QtCore as qtc
import os
import time
import csv
import multiprocessing
from model_table import TableModel
from model_table_pd import DataFrameModel


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

    # TODO: import option for stored config file
