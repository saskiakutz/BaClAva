# Title     : Bayesian run part
# Objective : with hdf5 import
# Adapted from: Griffié et al.
# Adapted and written by: Saskia Kutz

run_fun <- function(
  newfolder,
  bayes_model,
  datasource,
  clustermethod,
  parallel,
  cores,
  xlim = c(0, 3000),
  ylim = c(0, 3000),
  rpar,
  thpar,
  datacol,
  dirichlet_alpha,
  bayes_background) {
  source("./pythonr/package_list.R")
  source("./pythonr/exporting_hdf5.R")
  source("./pythonr/internal_bayesian.R")
  l_ply(newfolder, function(foldername) {
    if (bayes_model == "Gaussian(prec)") {
      model <- bayes_model
      histbins <- c(10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 510, 530, 550, 570, 590)
      histvalues <- c(8, 57, 104, 130, 155, 168, 197, 205, 216, 175, 123, 91, 74, 32, 24, 22, 12, 11, 6, 5, 3, 5, 1, 3, 0, 4, 0, 1, 1, 1)
      rseq <- seq(rpar[1], rpar[2], by = rpar[3])
      thseq <- seq(thpar[1], thpar[2], by = thpar[3])
      if (length(bayes_background) == 0 |
        length(dirichlet_alpha) == 0) {
        useplabel <- FALSE
        bayes_background <- NULL
        dirichlet_alpha <- NULL
      }
      else {
        useplabel <- TRUE
      }
      if (parallel == 0) {
        process <- "sequential"
      }
      else {
        process <- "parallel"
      }
    }
    else {
      stop("Haven't implemented anything else!")
    }

    o <- order(histbins)
    histbins <- histbins[o]
    histvalues <- histvalues[o]
    f <- approxfun(histbins, histvalues, yleft = histvalues[1],
                   yright = histvalues[length(histvalues)])
    cst <- integrate(f, lower = histbins[o[1]], upper = histbins[length(histbins)])$value

    psd <- function(sd) {
      log(f(sd)) - log(cst)
    }

    minsd <- histbins[1]
    maxsd <- histbins[length(histbins)]

    datasets <- list.files(file.path(foldername), pattern = "*.h5")
    datasets <- datasets[datasets != "../run_config.txt"]
    # datasets = datasets[datasets != "run_config.txt"]

    l_ply(file.path(datasets), function(filename) {
      datah5 <- H5Fopen(file.path(foldername, filename))
      # columns in data
      pts <- datah5$data[, c(datacol[1], datacol[2])]
      sds <- datah5$data[, datacol[3]]
      if (datasource == "experiment") {
        # limits of dataset set by the min/max of the localisations
        xlim <- c(min(pts[, 1]), max(pts[, 1]))
        ylim <- c(min(pts[, 2]), max(pts[, 2]))
      }

      write_metadata_df(datah5, datacol, 'data', 'datacolumns')
      # did <- H5Dopen(datah5, 'data')
      # h5writeAttribute(did, attr = datacol, name = 'datacolumns')
      # H5Dclose(did)

      if (process == "sequential") {
        res <- Kclust_sequential(
          pts = pts,
          sds = sds,
          xlim = xlim,
          ylim = ylim,
          psd = psd,
          minsd = minsd,
          maxsd = maxsd,
          useplabel = useplabel,
          alpha = dirichlet_alpha,
          pb = bayes_background,
          score = TRUE,
          rlabel = TRUE,
          rseq = rseq,
          thseq = thseq,
          clustermethod = clustermethod
        )
        writeRes_seq(res, datah5)
      }
      else {
        res <- Kclust_parallel(
          pts = pts,
          sds = sds,
          xlim = xlim,
          ylim = ylim,
          psd = psd,
          minsd = minsd,
          maxsd = maxsd,
          useplabel = useplabel,
          alpha = dirichlet_alpha,
          pb = bayes_background,
          score = TRUE,
          rlabel = TRUE,
          rseq = rseq,
          thseq = thseq,
          clustermethod = clustermethod,
          numCores = cores
        )
        writeRes_r_vs_th(
          res = res,
          rseq = rseq,
          thseq = thseq,
          datah5
        )
        writeRes_labels(
          res = res,
          rseq = rseq,
          thseq = thseq,
          datah5
        )
      }
      H5Fclose(datah5)
    })
  })
  h5closeAll()
  return(print("done"))
  gc()
}
