# Title     : Python to R connection
# Objective : Data preparation for and connection to R
# Written by: Saskia Kutz

try:
    import rpy2.robjects as r_objects
    from rpy2.robjects.packages import importr
    from rpy2.robjects import numpy2ri
    import rpy2.robjects.packages as rpackages
    from rpy2.robjects.vectors import BoolVector
except OSError as e:
    try:
        import os

        if os.name == 'nt':
            os.environ['R_HOME'] = 'C:\\Program Files\\R\\R-4.1.0'
            os.environ['PATH'] += os.pathsep + 'C:\\Program Files\\R\\R-4.1.0\\bin\\x64\\'
            os.environ['PATH'] += os.pathsep + 'C:\\Program Files\\R\\R-4.1.0\\'
        import rpy2.robjects as r_objects
        from rpy2.robjects.packages import importr
        from rpy2.robjects import numpy2ri
        import rpy2.robjects.packages as rpackages
        from rpy2.robjects.vectors import BoolVector
    except OSError:
        raise (e)
from os import listdir
from os.path import isfile, join

import numpy as np


class PythonToR:
    base = importr('base')
    r = r_objects.r

    def r_simulation(self, input_dic):
        """Data preparation and connection to simulation part in module 1a"""

        self.r.source('./pythonr/simulate.R')

        numpy2ri.activate()
        xlim = np.array([input_dic.get('roixmin'), input_dic.get('roixmax')])
        ylim = np.array([input_dic.get('roiymin'), input_dic.get('roiymax')])
        gammaparams = np.array([input_dic.get('alpha'), input_dic.get('beta')])
        ab = np.array([input_dic.get('a'), input_dic.get('b')])

        self.r.simulation_fun(
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

    def r_smlm_simulation(self, input_dic):
        """Data preparation and connection to data simulation part in module 1b"""

        self.r.source('./pythonr/simulation_smlm.R')
        numpy2ri.activate()
        self.r.make_plot(
            SizeX=input_dic.get('pixel_x'),
            SizeY=input_dic.get('pixel_y'),
            indent=input_dic.get('pixel_indent'),
            pixel_size=input_dic.get('pixel_size'),
            number_of_clusters=input_dic.get('n_clusters'),
            cluster_radius=input_dic.get('radius_cluster'),
            distance_between_clusters=2 / 3 * input_dic.get('radius_cluster'),
            FWHM=input_dic.get('PSF_FWHM'),
            max_intensity=input_dic.get('PSF_intensity'),
            on=input_dic.get('on_rate'),
            off=input_dic.get('off_rate'),
            frames=input_dic.get('n_frames'),
            exposure=input_dic.get('exposure_time') / 1000,
            simulations=input_dic.get('n_simulation'),
            stack_or_single=BoolVector([input_dic.get('tiff_stack')]),
            noise=BoolVector([input_dic.get('noise')]),
            density_or_molecules=1,
            clusters_density=input_dic.get('density_per_cluster'),
            background_density=input_dic.get('density_background'),
            directory_folder=input_dic.get('directory')
        )
        numpy2ri.deactivate()
        print('done')

    def r_bayesian_run(self, input_dic, status, conversion):
        """data preparation and connection to Bayesian engine in module 2"""

        self.r.source('./pythonr/run_hdf5.R')
        if len(status) == 2:
            ncores = status.get('cores')
        else:
            ncores = 0
        numpy2ri.activate()
        rseq = np.array([input_dic.get('rmin'), input_dic.get('rmax'), input_dic.get('rstep')])
        thseq = np.array([input_dic.get('thmin'), input_dic.get('thmax'), input_dic.get('thstep')])
        cols = np.array([input_dic.get('xcol'), input_dic.get('ycol'), input_dic.get('sdcol')])

        self.r.run_fun(
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
            bayes_background=input_dic.get('background'),
            micro_meter=BoolVector([conversion])
        )

        numpy2ri.deactivate()
        print("done")

    def r_post_processing(self, input_dic):
        """data preparation and connection to postprocessing part of module 3"""

        self.r.source("./pythonr/postprocessing_hdf5.R")
        numpy2ri.activate()
        storage_endings = np.array(input_dic.get('options'))
        if input_dic.get('unit') == 'nanometre':
            length = 'nm'
        else:
            length = 'um'
        self.r.post_fun(
            newfolder=input_dic.get('directory'),
            meter_unit=length,
            makeplot=BoolVector([input_dic.get('storeplots')]),
            storage=storage_endings,
            superplot=BoolVector([input_dic.get('superplot')]),
            separateplots=BoolVector([input_dic.get('separateplots')]),
            flipped=BoolVector([input_dic.get('flipped_y')])
        )
        numpy2ri.deactivate()
        print("done")

    def check_dataset_type(self, directory):
        """check for data type and converting to hdf5 if necessary"""

        if not any(name.endswith('.h5') for name in listdir(directory)):
            onlyfiles = [f for f in listdir(directory) if
                         isfile(join(directory, f)) and f not in ['sim_parameters.txt', 'run_config.txt', ]]
            convertfiles = [f for f in onlyfiles if
                            (f.endswith('.txt') or f.endswith('.csv')) and not f.endswith('summary.txt')]
            if convertfiles:
                self.r.source('./pythonr/convert.R')
                numpy2ri.activate()
                self.r.convert_hdf5(directory, convertfiles)
                numpy2ri.deactivate()

    def test_function(self, input_dic):
        self.r.source("./pythonr/plot_functions.R")
        self.r.source("./pythonr/package_list.R")

        numpy2ri.activate()
        storage_endings = np.array(input_dic.get('options'))
        self.r.plot_save(expname=input_dic.get('directory'), gg_plot_name='test2', storage_opt=storage_endings)
        numpy2ri.deactivate()
