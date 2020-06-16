from tkinter import Tk, BOTH, X, LEFT, END
from tkinter.ttk import Frame, Label, Entry, Button, Combobox
from tkinter.filedialog import askdirectory
import numpy as np


class Application(Frame):

    def __init__(self):
        super().__init__()
        self.name_dic = "~/PycharmProjects/Bayesian_analysis_GUI"
        self.entry_sim = None
        self.entry_std = None
        self.entry_bg = None
        self.combo_model = None
        self.entry_molecules = None
        self.entry_clusters = None
        self.button_dir = None
        self.entry_roi_x = None
        self.entry_roi_y = None
        self.entry_folder_name = None
        self.entry_gamma = None
        self.entry_multi = None
        self.entry_mols_multi = None
        self.entry_prop_multi = None
        self.entry_bg_dis = None
        self.init_user_interface()

    def init_user_interface(self):
        self.master.title("Simulation")
        self.pack(fill=BOTH, expand=True)

        frame_clusters = Frame(self)
        frame_clusters.pack(fill=X)
        label_clusters = Label(frame_clusters, text="number of clusters", width=30)
        label_clusters.pack(side=LEFT, padx=5, pady=10)
        self.entry_clusters = Entry(frame_clusters, width=20)
        self.entry_clusters.insert(END, '10')
        self.entry_clusters.pack(fill=X, padx=5, pady=10)

        frame_molecules = Frame(self)
        frame_molecules.pack(fill=X)
        label_molecules = Label(frame_molecules, text="number of molecules", width=30)
        label_molecules.pack(side=LEFT, padx=5, pady=5)
        self.entry_molecules = Entry(frame_molecules, width=20)
        self.entry_molecules.insert(END, '100')
        self.entry_molecules.pack(fill=X, padx=5, pady=5)

        frame_model = Frame(self)
        frame_model.pack(fill=X)
        label_model = Label(frame_model, text="model", width=30)
        label_model.pack(side=LEFT, padx=5, pady=5)
        self.combo_model = Combobox(frame_model, width=20)
        self.combo_model['values'] = ('Gaussian', 'no other model')
        self.combo_model.current(0)
        self.combo_model.pack(fill=X, padx=5, pady=5)

        frame_std = Frame(self)
        frame_std.pack(fill=X)
        label_std = Label(frame_std, text="standard deviation [nm]", width=30)
        label_std.pack(side=LEFT, padx=5, pady=5)
        self.entry_std = Entry(frame_std, width=20)
        self.entry_std.insert(END, '50')
        self.entry_std.pack(fill=X, padx=5, pady=5)

        frame_bg = Frame(self)
        frame_bg.pack(fill=X)
        label_bg = Label(frame_bg, text="background", width=30)
        label_bg.pack(side=LEFT, padx=5, pady=5)
        self.entry_bg = Entry(frame_bg, width=20)
        self.entry_bg.insert(END, '0.5')
        self.entry_bg.pack(fill=X, padx=5, pady=5)

        frame_bg_dis = Frame(self)
        frame_bg_dis.pack(fill=X)
        label_bg_dis = Label(frame_bg_dis, text="background distribution", width=30)
        label_bg_dis.pack(side=LEFT, padx=5, pady=5)
        self.entry_bg_dis = Entry(frame_bg_dis, width=20)
        self.entry_bg_dis.insert(END, '1,1')
        self.entry_bg_dis.pack(fill=X, padx=5, pady=5)

        frame_roi_x = Frame(self)
        frame_roi_x.pack(fill=X)
        label_roi_x = Label(frame_roi_x, text="ROI x dimension [nm, nm]", width=30)
        self.entry_roi_x = self.roi(frame_roi_x, label_roi_x)

        frame_roi_y = Frame(self)
        frame_roi_y.pack(fill=X)
        label_roi_y = Label(frame_roi_y, text="ROI y dimension [nm, nm]", width=30)
        self.entry_roi_y = self.roi(frame_roi_y, label_roi_y)

        frame_sim = Frame(self)
        frame_sim.pack(fill=X)
        label_sim = Label(frame_sim, text="number of simulations", width=30)
        label_sim.pack(side=LEFT, padx=5, pady=5)
        self.entry_sim = Entry(frame_sim, width=20)
        self.entry_sim.insert(END, '10')
        self.entry_sim.pack(fill=X, padx=5, pady=5)

        frame_gamma = Frame(self)
        frame_gamma.pack(fill=X)
        label_gamma = Label(frame_gamma, text="Gamma parameters", width=30)
        label_gamma.pack(side=LEFT, padx=5, pady=5)
        self.entry_gamma = Entry(frame_gamma, width=20)
        self.entry_gamma.insert(END, '5,0.166667')
        self.entry_gamma.pack(fill=X, padx=5, pady=5)

        frame_multi = Frame(self)
        frame_multi.pack(fill=X)
        label_multi = Label(frame_multi, text="multimerisation", width=30)
        label_multi.pack(side=LEFT, padx=5, pady=5)
        self.entry_multi = Entry(frame_multi, width=20)
        self.entry_multi.insert(END, '1')
        self.entry_multi.pack(fill=X, padx=5, pady=5)

        frame_mols_multi = Frame(self)
        frame_mols_multi.pack(fill=X)
        label_mols_multi = Label(frame_mols_multi, text="molecules per multimerisation", width=30)
        label_mols_multi.pack(side=LEFT, padx=5, pady=5)
        self.entry_mols_multi = Entry(frame_mols_multi, width=20)
        self.entry_mols_multi.insert(END, '2000')
        self.entry_mols_multi.pack(fill=X, padx=5, pady=5)

        frame_prop_multi = Frame(self)
        frame_prop_multi.pack(fill=X)
        label_prop_multi = Label(frame_prop_multi, text="proportion of multimerisation", width=30)
        label_prop_multi.pack(side=LEFT, padx=5, pady=5)
        self.entry_prop_multi = Entry(frame_prop_multi, width=20)
        self.entry_prop_multi.insert(END, '0.1')
        self.entry_prop_multi.pack(fill=X, padx=5, pady=5)

        frame_folder_name = Frame(self)
        frame_folder_name.pack(fill=X)
        label_folder_name = Label(frame_folder_name, text="Folder name", width=30)
        label_folder_name.pack(side=LEFT, padx=5, pady=5)
        self.entry_folder_name = Entry(frame_folder_name, width=20)
        self.entry_folder_name.insert(END, "simulation")
        self.entry_folder_name.pack(fill=X, padx=5, pady=5)

        frame_dir = Frame(self)
        frame_dir.pack(fill=X)
        label_dir = Label(frame_dir, text="Choose directory", width=30)
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
        self.name_dic = askdirectory()
        print(self.name_dic)
        # TODO: directory should be used for further processing

    def callback_sim(self):
        print("Simulations:", self.entry_sim.get())
        print("Number of clusters:", self.entry_clusters.get())
        # TODO: connection to R script

    def get_sim_parameters(self):
        pass  # TODO: might help callback_sim()


def main():
    root = Tk()
    root.geometry("400x450+300+300")
    app = Application()
    app.mainloop()


if __name__ == '__main__':
    main()
