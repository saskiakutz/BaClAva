from PyQt5 import QtWidgets as qtw
from PyQt5 import QtGui as qtg
from modules.module_one_a_simulation import MainWindowSimulation
from modules.module_one_b_smlm_simulation import MainWindowSimulationSMLM
from modules.module_two_Bayesian import MainWindowBayesian
from modules.module_three_post import MainWindowPost
from modules.module_four_filtering import MainWindowFiltering


class ViewSoftware(qtw.QWidget):
    # noinspection PyArgumentList
    def __init__(self):
        """setting up the layout of the GUI and connecting the modules to each tab"""
        super().__init__()

        self.main_layout = qtw.QVBoxLayout()
        tab_layout = qtw.QHBoxLayout()
        self.tab_widget = qtw.QTabWidget()
        self.tab_widget.setStyleSheet('QTabBar { font-size: 13pt; font-family: Arial; }')
        # self.setCentralWidget(self.tab_widget)

        self.subwidget_1 = qtw.QWidget(self)
        self.grid_layout = qtw.QGridLayout()
        self.subwidget_1.setLayout(self.grid_layout)
        self.subwidget_2 = qtw.QWidget(self)
        self.grid_layout2 = qtw.QGridLayout()
        self.subwidget_2.setLayout(self.grid_layout2)
        self.subwidget_3 = qtw.QWidget(self)
        self.grid_layout3 = qtw.QGridLayout()
        self.subwidget_3.setLayout(self.grid_layout3)
        self.subwidget_4 = qtw.QWidget(self)
        self.grid_layout4 = qtw.QGridLayout()
        self.subwidget_4.setLayout(self.grid_layout4)
        self.subwidget_5 = qtw.QWidget(self)
        self.grid_layout5 = qtw.QGridLayout()
        self.subwidget_5.setLayout(self.grid_layout5)
        self.tab_widget.addTab(self.subwidget_1, 'Module 1a: Simulation')
        self.main_simulation = MainWindowSimulation()
        self.subwidget_1.layout().addWidget(self.main_simulation)
        self.tab_widget.addTab(self.subwidget_2, 'Module 1b: SMLM simulation')
        self.main_simulation_STORM = MainWindowSimulationSMLM()
        self.subwidget_2.layout().addWidget(self.main_simulation_STORM)
        self.tab_widget.addTab(self.subwidget_3, 'Module 2: Bayesian engine')
        self.main_run = MainWindowBayesian()
        self.subwidget_3.layout().addWidget(self.main_run)
        self.tab_widget.addTab(self.subwidget_4, 'Module 3: Post processing')
        self.main_post = MainWindowPost()
        self.subwidget_4.layout().addWidget(self.main_post)
        self.main_filtering = MainWindowFiltering()
        self.subwidget_5.layout().addWidget(self.main_filtering)
        self.tab_widget.addTab(self.subwidget_5, 'Module 4: Cluster Filtering')
        # self.tab_widget.currentChanged(self.set_statusbar)
        tab_layout.addWidget(self.tab_widget)
        self.main_layout.addLayout(tab_layout)

        self.setLayout(self.main_layout)
