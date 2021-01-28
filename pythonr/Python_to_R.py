import rpy2.robjects as r_objects
from rpy2.robjects.packages import importr
from rpy2.robjects import numpy2ri
import rpy2.robjects.packages as rpackages
from rpy2.robjects.vectors import BoolVector
import numpy as np
from os import getcwd, listdir
from os.path import isfile, join


class PythonToR():
    def r_simulation(self, input_dic):
        # call R simulation
        base = importr('base')
        r = r_objects.r
        r.source('./pythonr/simulate.R')

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

    def r_bayesian_run(self, input_dic, status):
        r = r_objects.r
        r.source('./pythonr/run_hdf5.R')
        if len(status) == 2:
            ncores = status.get('cores')
        else:
            ncores = 0
        numpy2ri.activate()
        if input_dic.get('datasource') == 'simulation':
            xlim = np.array([input_dic.get('roixmin'), input_dic.get('roixmax')])
            ylim = np.array([input_dic.get('roiymin'), input_dic.get('roiymax')])
        rseq = np.array([input_dic.get('rmin'), input_dic.get('rmax'), input_dic.get('rstep')])
        thseq = np.array([input_dic.get('thmin'), input_dic.get('thmax'), input_dic.get('thstep')])
        cols = np.array([input_dic.get('xcol'), input_dic.get('ycol'), input_dic.get('sdcol')])

        if input_dic.get('datasource') == 'simulation':
            r.run_fun(
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
                datacol=cols,
                dirichlet_alpha=input_dic.get('alpha'),
                bayes_background=input_dic.get('background')
            )
        else:
            r.run_fun(
                newfolder=input_dic.get('directory'),
                bayes_model=input_dic.get('model'),
                datasource=input_dic.get('datasource'),
                clustermethod=input_dic.get('clustermethod'),
                parallel=status.get('parallel'),
                cores=ncores,
                rpar=rseq,
                thpar=thseq,
                datacol=cols,
                dirichlet_alpha=input_dic.get('alpha'),
                bayes_background=input_dic.get('background')
            )
        numpy2ri.deactivate()
        print("done")

    def r_post_processing(self, input_dic):
        r = r_objects.r
        r.source("./pythonr/postprocessing_hdf5.R")
        numpy2ri.activate()
        r.post_fun(
            newfolder=input_dic.get('directory'),
            # datasource=input_dic.get('datasource'),
            # process=input_dic.get('computation'),
            makeplot=BoolVector([input_dic.get('storeplots')]),
            superplot=BoolVector([input_dic.get('superplot')]),
            separateplots=BoolVector([input_dic.get('separateplots')])
        )
        numpy2ri.deactivate()
        print("done")

    def r_test(self, input_test):
        input_test = 4
        print("Length of parameter: ", input_test)
        r = r_objects.r
        print(getcwd())
        r.source("run.R")
        numpy2ri.activate()
        temp = r.test_function(input_test)
        print(temp)
        numpy2ri.deactivate()

    def check_dataset_type(self, directory):
        onlyfiles = [f for f in listdir(directory) if
                     isfile(join(directory, f)) and f not in ['sim_parameters.txt', 'run_config.txt', ]]
        convertfiles = [f for f in onlyfiles if
                        (f.endswith('.txt') or f.endswith('.csv')) and not f.endswith('summary.txt')]
        if convertfiles:
            r = r_objects.r
            r.source('./pythonr/convert.R')
            numpy2ri.activate()
            r.convert_hdf5(directory, convertfiles)
            numpy2ri.deactivate()
