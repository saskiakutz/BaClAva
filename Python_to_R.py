import rpy2.robjects as r_objects
from rpy2.robjects.packages import importr
from rpy2.robjects import numpy2ri
import rpy2.robjects.packages as rpackages
from rpy2.robjects.vectors import StrVector
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


def r_bayesian_run(input_dic, status):
    print("input: ", input_dic)
    print("status: ", status)
    print(len(status))
    r = r_objects.r
    packnames = [
        'devtools', "dplyr", "pryr", "ggpubr", "splancs", "igraph", "RSMLM", "tictoc", "geometry", "doParallel",
        "data.table", "plyr"]
    r.source('run.R')
    if len(status) == 2:
        ncores = input_dic.get('cores')
    else:
        ncores = 0
    numpy2ri.activate()
    xlim = np.array([input_dic.get('roixmin'), input_dic.get('roixmax')])
    ylim = np.array([input_dic.get('roiymin'), input_dic.get('roiymax')])
    rseq = np.array([input_dic.get('rmin'), input_dic.get('rmax'), input_dic.get('rstep')])
    thseq = np.array([input_dic.get('thmin'), input_dic.get('thmax'), input_dic.get('thstep')])

    temp = r.run_fun(
        newfolder=input_dic.get('directory'),
        bayes_model=input_dic.get('model'),
        datasource=input_dic.get('datasource'),
        clustermethod=input_dic.get('clustermethod'),
        parallel=status.get('parallel'),
        cores=ncores,
        xlim=xlim,
        ylim=ylim,
        rpar=rseq,
        thpar=thseq,
        dirichlet_alpha=input_dic.get('alpha'),
        bayes_background=input_dic.get('background'),
        run_packages=packnames
    )
    print(temp)
    numpy2ri.deactivate()
    print("done")


def r_test(input_test):
    print("Length of parameter: ", input_test)
    r = r_objects.r
    r.source("run.R")
    packnames = [
        'devtools', "dplyr", "pryr", "ggpubr", "splancs", "igraph", "RSMLM", "tictoc", "geometry", "doParallel",
        "data.table", "plyr"]
    temp = r.test_function(input_test, packnames)
    print(temp)
