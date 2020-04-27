from tkinter import Tk, TOP, BOTH, X, LEFT, END, RIGHT
from tkinter.ttk import Frame, Label, Entry, Button, Combobox
from tkinter.filedialog import askdirectory
import numpy as np


class Application(Frame):

    def __init__(self):
        super().__init__()
        self.entry_sim = None
        self.entry_std = None
        self.entry_bg = None
        self.combo_model = None
        self.entry_molecules = None
        self.entry_clusters = None
        self.button_dir = None
        self.entry_roi_x = None
        self.entry_roi_y = None
        self.init_user_interface()

    def init_user_interface(self):
        self.master.title("Simulation")
        self.pack(fill=BOTH, expand=True)

        frame_clusters = Frame(self)
        frame_clusters.pack(fill=X)
        label_clusters = Label(frame_clusters, text="number of clusters", width=25)
        label_clusters.pack(side=LEFT, padx=5, pady=10)
        self.entry_clusters = Entry(frame_clusters, width=20)
        self.entry_clusters.insert(END, '10')
        self.entry_clusters.pack(fill=X, padx=5, pady=10)

        frame_molecules = Frame(self)
        frame_molecules.pack(fill=X)
        label_molecules = Label(frame_molecules, text="number of molecules", width=25)
        label_molecules.pack(side=LEFT, padx=5, pady=5)
        self.entry_molecules = Entry(frame_molecules, width=20)
        self.entry_molecules.insert(END, '100')
        self.entry_molecules.pack(fill=X, padx=5, pady=5)

        frame_model = Frame(self)
        frame_model.pack(fill=X)
        label_model = Label(frame_model, text="model", width=25)
        label_model.pack(side=LEFT, padx=5, pady=5)
        self.combo_model = Combobox(frame_model, width=20)
        self.combo_model['values'] = ('Gaussian', 'no other model')
        self.combo_model.current(0)
        self.combo_model.pack(fill=X, padx=5, pady=5)

        frame_std = Frame(self)
        frame_std.pack(fill=X)
        label_std = Label(frame_std, text="standard deviation [nm]", width=25)
        label_std.pack(side=LEFT, padx=5, pady=5)
        self.entry_std = Entry(frame_std, width=20)
        self.entry_std.insert(END, '50')
        self.entry_std.pack(fill=X, padx=5, pady=5)

        frame_bg = Frame(self)
        frame_bg.pack(fill=X)
        label_bg = Label(frame_bg, text="background", width=25)
        label_bg.pack(side=LEFT, padx=5, pady=5)
        self.entry_bg = Entry(frame_bg, width=20)
        self.entry_bg.insert(END, '0.5')
        self.entry_bg.pack(fill=X, padx=5, pady=5)

        frame_roi_x = Frame(self)
        frame_roi_x.pack(fill=X)
        label_roi_x = Label(frame_roi_x, text="ROI x dimension [nm, nm]", width=25)
        self.entry_roi_x = self.roi(frame_roi_x, label_roi_x)

        frame_roi_y = Frame(self)
        frame_roi_y.pack(fill=X)
        label_roi_y = Label(frame_roi_y, text="ROI y dimension [nm, nm]", width=25)
        self.entry_roi_y = self.roi(frame_roi_y, label_roi_y)

        frame_sim = Frame(self)
        frame_sim.pack(fill=X)
        label_sim = Label(frame_sim, text="number of simulations", width=25)
        label_sim.pack(side=LEFT, padx=5, pady=5)
        self.entry_sim = Entry(frame_sim, width=20)
        self.entry_sim.insert(END, '10')
        self.entry_sim.pack(fill=X, padx=5, pady=5)

        frame_dir = Frame(self)
        frame_dir.pack(fill=X)
        label_dir = Label(frame_dir, text="Choose directory", width=25)
        label_dir.pack(side=LEFT, padx=5, pady=5)
        self.button_dir = Button(frame_dir, text="Directory", command=self.callback_dir)
        self.button_dir.pack(fill=X, padx=5, pady=5)

        frame_start = Frame(self)
        frame_start.pack(fill=X)
        button_start = Button(frame_start, text="Start simulation", command=self.callback_sim)
        button_start.pack(fill=X, padx=5, pady=10)

    @staticmethod
    def roi(frame_roi, label_roi):
        label_roi.pack(side=LEFT, padx=5, pady=5)
        entry_roi_1 = Entry(frame_roi, width=10)
        entry_roi_1.insert(END, '0')
        entry_roi_1.pack(side=LEFT, padx=5, pady=5)
        entry_roi_2 = Entry(frame_roi, width=10)
        entry_roi_2.insert(END, '3000')
        entry_roi_2.pack(side=LEFT, padx=5, pady=5)
        return np.array([entry_roi_1, entry_roi_2])

    def callback_dir(self):
        name = askdirectory()
        print(name)
        # TODO

    def callback_sim(self):
        print("Simulations:", self.entry_sim.get())
        print("Number of clusters:", self.entry_clusters.get())

        # TODO


def main():
    root = Tk()
    root.geometry("400x280+300+300")
    app = Application()
    app.mainloop()


if __name__ == '__main__':
    main()
