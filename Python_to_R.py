import rpy2.robjects as r_objects
from rpy2.robjects.packages import importr


# get parameters
def get_sim_parameters():
    sim_dic = {}
    with open("sim_params.txt") as file_:
        for line in file_:
            line_entry = line.rsplit("\n")
            (key, val) = line_entry[0].split("=")
            sim_dic[key] = val


# call R simulation
base = importr('base')
r = r_objects.r
r.source('simulate.R')

r.simulation_fun()
print("done")
