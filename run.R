run_fun <- function(
  newfolder,
  bayes_model,
  datasource,
  clustermethod,
  parallel,
  cores,
  xlim,
  ylim,
  rpar,
  thpar,
  dirichlet_alpha,
  bayes_background) {
  source("internal.R")
  tic('code')
  l_ply(newfolder, function(foldername) {
    if (bayes_model == "Gaussian(prec)") {
      model = bayes_model
      histbins = c(10, 30, 50, 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410, 430, 450, 470, 490, 510, 530, 550, 570, 590)
      histvalues = c(8, 57, 104, 130, 155, 168, 197, 205, 216, 175, 123, 91, 74, 32, 24, 22, 12, 11, 6, 5, 3, 5, 1, 3, 0, 4, 0, 1, 1, 1)
      rseq = seq(rpar[1], rpar[2], by = rpar[3])
      thseq = seq(thpar[1], thpar[2], by = thpar[3])
      if (length(bayes_background) == 0 |
        length(dirichlet_alpha) == 0) {
        useplabel = FALSE
        bayes_background = NULL
        dirichlet_alpha = NULL
      }
      else {
        useplabel = TRUE
      }
      if (parallel == 0) {
        process = "sequential"
      }
      else {
        process = "parallel"
      }
    }
    else {
      stop("Haven't implemented anything else!")
    }

    o = order(histbins)
    histbins = histbins[o]
    histvalues = histvalues[o]
    f = approxfun(histbins, histvalues, yleft = histvalues[1],
                  yright = histvalues[length(histvalues)])
    cst = integrate(f, lower = histbins[o[1]], upper = histbins[length(histbins)])$value

    psd <- function(sd) {
      log(f(sd)) - log(cst)
    }

    minsd = histbins[1]
    maxsd = histbins[length(histbins)]

    if (datasource == "experiment") {

      # copy each experimental dataset into a seperate folder
      # exclude config.txt
      # will not be done in reclustering

      datasets = list.files(file.path(foldername), pattern = "*.txt")
      datasets = datasets[datasets != "run_config.txt"]

      if (!length(datasets) == 0) {

        sapply(datasets, function(dataset) {
          newfolder <- file.path(paste0(foldername, "/", dataset, sep = ""))
          newfolder <- substr(newfolder, 1, nchar(newfolder) - 4)
          dir.create(newfolder, showWarnings = F)
          file.copy(
            from = paste0(foldername, "/", dataset),
            to = newfolder,
            recursive = F,
            copy.mode = T
          )
          file.remove(paste0(foldername, "/", dataset))
        })
      }
    }

    ld = list.dirs(foldername, recursive = FALSE)
    ld = ld[ld != foldername]
    ld = ld[ld != paste0(ld, "postprocessing")]
    ld = ld[ld != paste0(ld, "postprocessing_ground_truth")]

    l_ply(file.path(ld), function(foldername) {
      if (datasource == "simulation") {
        data = read.csv(file.path(paste0(foldername, "/data.txt", sep = "")))
        # columns in simulation dataset
        pts = data[, 1:2]
        sds = data[, 3]
      }else {
        data <- import_data(foldername)

        # columns in SMAP dataset TODO: let user choose the columns for other localistion implementations
        pts = data[, 1:2]
        sds = data[, 4]
        # limits of dataset set by the min/max of the localisations
        xlim = c(min(pts[, 1]), max(pts[, 1]))
        ylim = c(min(pts[, 2]), max(pts[, 2]))
      }

      if (process == "sequential") {
        res = Kclust_sequential(
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
        writeRes(res, file.path(paste0(foldername, "/r_vs_thresh.txt", sep = "")),
                 file.path(paste0(foldername, "/labels", sep = "")))
      }
      else {
        res = Kclust_parallel(
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
          file.path(paste(
            foldername, "/r_vs_thresh.txt", sep = ""
          ))
        )
        writeRes_labels(
          res = res,
          rseq = rseq,
          thseq = thseq,
          file.path(paste(foldername, "/labels", sep = ""))
        )
      }
    })
  })
  toc()
}


test_function <- function(input_para, my_packages) {
  source("internal.R")
  tic("test_run")
  #lapply(my_packages, require(quietly = TRUE), character.only = TRUE)
  temp <- length(input_para)
  toc()
  return(temp)
}
