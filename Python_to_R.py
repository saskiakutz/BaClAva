import rpy2.robjects as r_objects
from rpy2.robjects.packages import importr
from rpy2.robjects import numpy2ri
import numpy as np


def r_simulation(input_dic):
    # call R simulation
    base = importr('base')
    r = r_objects.r
    r.source('simulate.R')

    print(input_dic.get("sdcluster"))

    numpy2ri.activate()
    xlim = np.array([input_dic.get('roixmin'), input_dic.get('roixmax')])
    ylim = np.array([input_dic.get('roiymin'), input_dic.get('roiymax')])
    gammaparams = np.array([input_dic.get('alpha'), input_dic.get('beta')])
    ab = np.array([input_dic.get('a'), input_dic.get('b')])

    r.simulation_fun(
        newfolder=input_dic.get('directory'),
        nclusters=input_dic.get('nclusters'),
        molspercluster=input_dic.get('molspercluster'),
        background=input_dic.get('background'),
        xlim=xlim,
        ylim=ylim,
        gammaparams=gammaparams,
        nsim=input_dic.get('nsim'),
        sdcluster=input_dic.get('sdcluster'),
        ab=ab
    )
    numpy2ri.deactivate()
    print("done")
    # TODO: multimerisation not ready yet
