# Title     : Slider Model
# Objective : Slider for Module 4
# Written by: Saskia Kutz

from PyQt5 import QtWidgets as qtw
from PyQt5 import QtCore as qtc


class Slider(qtw.QWidget):
    """Slider class"""

    def __init__(self, name, minimum, maximum, parent=None):

        super(Slider, self).__init__(parent=parent)
        self.horizontalLayout = qtw.QHBoxLayout(self)
        self.label = qtw.QLabel(self)
        self.horizontalLayout.addWidget(self.label)
        self.verticalLayout = qtw.QVBoxLayout()
        spacer_item = qtw.QSpacerItem(0, 20, qtw.QSizePolicy.Expanding, qtw.QSizePolicy.Minimum)
        self.verticalLayout.addItem(spacer_item)
        self.slider_label = qtw.QLabel(name)
        self.verticalLayout.addWidget(self.slider_label)
        spacer_item_2 = qtw.QSpacerItem(0, 20, qtw.QSizePolicy.Expanding, qtw.QSizePolicy.Minimum)
        self.verticalLayout.addItem(spacer_item_2)
        self.slider = qtw.QSlider(self)
        self.slider.setOrientation(qtc.Qt.Horizontal)
        self.verticalLayout.addWidget(self.slider)
        spacer_item_1 = qtw.QSpacerItem(0, 20, qtw.QSizePolicy.Expanding, qtw.QSizePolicy.Minimum)
        self.verticalLayout.addItem(spacer_item_1)
        self.horizontalLayout.addLayout(self.verticalLayout)
        self.resize(self.sizeHint())

        self.minimum = minimum
        self.maximum = maximum
        self.slider.setRange(self.minimum, self.maximum)
        self.slider.valueChanged.connect(self.set_label_value)
        self.x = None
        self.set_label_value(self.slider.value())

    def set_label_value(self, value):
        self.x = self.slider.value()
        self.label.setText("{0:.4g}".format(self.x))

    def update_min_max(self, min_new, max_new):
        self.minimum = min_new
        self.maximum = max_new
        self.slider.setRange(self.minimum, self.maximum)
