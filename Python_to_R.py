import rpy2.robjects as r_objects
from rpy2.robjects.packages import importr
from rpy2.robjects import numpy2ri
import numpy as np


def r_simulation(input_dic):
    # call R simulation
    base = importr('base')
    r = r_objects.r
    r.source('simulate.R')

    print(input_dic.get('roixmin'))
    print(input_dic.get('roixmax'))
    print(input_dic.get('roiymin'))
    print(input_dic.get('roiymax'))
    print(input_dic.get('alpha'))
    print(input_dic.get('beta'))
    print(input_dic.get('a'))
    print(input_dic.get('b'))

    numpy2ri.activate()
    test_array = np.array([input_dic.get('roixmin'), input_dic.get('roixmax')])

    r.test_fun(test_array)
    numpy2ri.deactivate()

    # r.simulation_fun(
    #     input_dic.get('directory'),
    #     input_dic.get('nclusters'),
    #     input_dic.get('molspercluster'),
    #     input_dic.get('background'),
    #     xlim,
    #     ylim,
    #     gammaparams,
    #     input_dic.get('nsim'),
    #     input_dic.get('sdcluster'),
    #     ab
    # )
    print("done")
    # TODO: add np.arrays to simulation_fun(). All keys in print statements have to get converted/combined to np.arrays
