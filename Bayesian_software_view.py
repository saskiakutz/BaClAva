from PyQt5 import QtWidgets as qtw
from modules.module_one_simulation import MainWindow_simulation
from modules.module_one_b_STORM_simulation import MainWindow_simulation_STORM
from modules.module_two_Bayesian import MainWindow_Bayesian
from modules.module_three_post import MainWindow_post


class View_software(qtw.QWidget):

    # noinspection PyArgumentList
    def __init__(self):
        super().__init__()

        self.main_layout = qtw.QVBoxLayout()
        tab_layout = qtw.QHBoxLayout()
        self.tab_widget = qtw.QTabWidget()
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
        self.tab_widget.addTab(self.subwidget_1, 'Module 1a: Simulation')
        self.main_simulation = MainWindow_simulation()
        self.subwidget_1.layout().addWidget(self.main_simulation)
        self.tab_widget.addTab(self.subwidget_2, 'Module 1b: STORM simulation')
        self.main_simulation_STORM = MainWindow_simulation_STORM()
        self.subwidget_2.layout().addWidget(self.main_simulation_STORM)
        self.tab_widget.addTab(self.subwidget_3, 'Module 2: Bayesian engine')
        self.main_run = MainWindow_Bayesian()
        self.subwidget_3.layout().addWidget(self.main_run)
        self.tab_widget.addTab(self.subwidget_4, 'Module 3: Postprocessing')
        self.main_post = MainWindow_post()
        self.subwidget_4.layout().addWidget(self.main_post)
        # self.tab_widget.currentChanged(self.set_statusbar)
        tab_layout.addWidget(self.tab_widget)
        self.main_layout.addLayout(tab_layout)

        self.setLayout(self.main_layout)
