# Title     : TODO
# Objective : TODO
# Created by: saskia-admin
# Created on: 2020-07-14

#  r = readLines(con = file.path(paste(foldername, "/config.txt", sep = "")))
#
#  get <-
#    function(type) {
#      i = grep(type, r)
#      strsplit(r[i], "=")[[1]][2]
#    }
#  as.v <- function(ch) {
#    as.numeric(strsplit(ch, ",")[[1]])
#  }
#
#  model = get("model")
#  {
#    if (model == "Gaussian(prec)") {
#      datasource = get("datasource")
#      if (datasource == "simulation") {
#        xlim = as.v(get("xlim"))
#        ylim = as.v(get("ylim"))
#      }
#      histbins = as.v(get("histbins"))
#      histvalues = as.v(get("histvalues"))
#      if (length(grep("pbackground", r)) == 0 |
#          length(grep("alpha", r)) == 0) {
#        useplabel = FALSE
#        pb = NULL
#        alpha = NULL
#      }
#      else {
#        useplabel = TRUE
#
#        pb = as.numeric(get("pbackground"))
#        alpha = as.numeric(get("alpha"))
#      }
##      if (length(grep("report",r)) == 0){
##        reportout = TRUE
##      }else{
##        reportout = as.numeric(get("report"))
##      }
##      if (length(grep("bestonly", r)) == 0) #TODO: not implemented in GUI
##        bestonly = FALSE
##      else
##        bestonly = as.numeric(get("bestonly")) > 0
#  if (length(grep("rseq",r))==0) rseq=seq(10, 200, by=5)
#  else {
#      rparams=as.v(get("rseq"))
#      rseq=seq(rparams[1], rparams[2], by=rparams[3])
#  }
#  if (length(grep("thseq",r))==0) thseq=seq(5, 500, by=5)
#  else {
#      thparams=as.v(get("thseq"))
#      thseq=seq(thparams[1], thparams[2], by=thparams[3])
#  }
#      if (length(grep("parallel", r)) == 0)
#        process = "sequential"
#      else {
#        process = as.numeric(get("parallel"))
#        if (process == 0) {
#          process = "sequential"
#        }
#        else{
#          process = "parallel"
#        }
#      }
#      if(process == "parallel"){
#        if(length(grep("cores", r)) == 0){
#          cores = detectCores()/2
#        }else{
#          cores = as.numeric(get("cores"))
#        }
#      }
##      if(length(grep("RAM",r)) != 0){ #TODO: can this be accomplished in Python?
##        RAMmaximum = as.numeric(get("RAM"))
##        RAMmaximum = RAMmaximum*10^9
##      }
##      if (length(grep("clustermethod", r)) == 0)
##        clustermethod = "K"
##      else {
##        method = as.numeric(get("clustermethod"))
##        if (method == 1) { #K by Griffié
##          clustermethod = "K"
##        }
##        else if (method == 2) { #DBSCAN by Griffié
##          clustermethod = "DBSCAN"
##        }
##        else if (method == 3){ #ToMATo by Pike
##          clustermethod = "ToMATo"
##        }
##        # else if (method == 4){ #2D Voronoi by Pike/Levet #TODO: implement Voronoi
##        #   clustermethod = "Voronoi"
##        # }
##        # else if ( method == 5){ #from dbscan package, only 1 parameter 'TODO: implement HDBSCAN
##        #   clustermethod = "HDBSCAN"
##        # }
##        else { # DBSCAN by Pike/Ester #TODO: implement faster DBSCAN
##          clustermethod = "DBSCAN2"
##        }
##      }
#    }
#    else {
#      stop("Haven't implemented anything else!")
#    }
#  }
#
#  o = order(histbins)
#  histbins = histbins[o]
#  histvalues = histvalues[o]
#  f = approxfun(histbins, histvalues, yleft = histvalues[1],
#                yright = histvalues[length(histvalues)])
#  cst = integrate(f, lower = histbins[o[1]], upper = histbins[length(histbins)])$value
#  psd <- function(sd) {
#    log(f(sd)) - log(cst)
#  }
#  minsd = histbins[1]
#  maxsd = histbins[length(histbins)]
#
#
#  if (datasource == "experiment") {
#
#    # copy each experimental dataset into a seperate folder
#    # exclude config.txt
#    # will not be done in reclustering
#
#    datasets = list.files(file.path(foldername), pattern = "*.txt")
#    datasets = datasets[datasets != "config.txt"]
#
#    if (!length(datasets) == 0) {
#
#      sapply(datasets, function(dataset) {
#        newfolder <- file.path(paste(foldername, "/", dataset, sep = ""))
#        newfolder <- substr(newfolder, 1, nchar(newfolder) - 4)
#        dir.create(newfolder, showWarnings = F)
#        file.copy(
#          from = paste0(foldername, "/", dataset),
#          to = newfolder,
#          recursive = F,
#          copy.mode = T
#        )
#        file.remove(paste0(foldername, "/", dataset))
#      })
#    }
#  }
#
#  ld = list.dirs(foldername, recursive = FALSE)
#  ld = ld[ld != foldername]
#  ld = ld[ld != paste0(ld,"postprocessing")]
#  ld = ld[ld != paste0(ld,"postprocessing_ground_truth")]
#
#
#  l_ply(file.path(ld), function(foldername){
#
#    if (datasource == "simulation") {
#      data = read.csv(file.path(paste(foldername, "/data.txt", sep = "")))
#      # columns in simulation dataset
#      pts = data[, 1:2]
#      sds = data[, 3]
#    }else {
#      data <- import_data(foldername)
#
#      # columns in SMAP dataset
#      pts = data[, 1:2]
#      sds = data[, 4]
#      # limits of dataset set by the min/max of the localisations
#      xlim = c(min(pts[, 1]), max(pts[, 1]))
#      ylim = c(min(pts[, 2]), max(pts[, 2]))
#    }
#
#    if (process == "sequential") {
#      res = Kclust_sequential(
#        pts = pts,
#        sds = sds,
#        xlim = xlim,
#        ylim = ylim,
#        psd = psd,
#        minsd = minsd,
#        maxsd = maxsd,
#        useplabel = useplabel,
#        alpha = alpha,
#        pb = pb,
#        score = TRUE,
#        rlabel = TRUE,
#        report = reportout,
#        rseq = rseq,
#        thseq = thseq,
#        clustermethod = clustermethod,
#        RAMmax = RAMmaximum,
#        RAMmodulo = 50
#      )
#      writeRes(res, file.path(paste(
#        foldername, "/r_vs_thresh.txt", sep = ""
#      )), file.path(paste(foldername, "/labels", sep = "")), bestonly = bestonly)
#    }
#    else{
#      res = Kclust_parallel(
#        pts = pts,
#        sds = sds,
#        xlim = xlim,
#        ylim = ylim,
#        psd = psd,
#        minsd = minsd,
#        maxsd = maxsd,
#        useplabel = useplabel,
#        alpha = alpha,
#        pb = pb,
#        score = TRUE,
#        rlabel = TRUE,
#        report = reportout,
#        rseq = rseq,
#        thseq = thseq,
#        clustermethod = clustermethod,
#        numCores = cores
#      )
#      writeRes_r_vs_th(
#        res = res,
#        rseq = rseq,
#        thseq = thseq,
#        file.path(paste(
#          foldername, "/r_vs_thresh.txt", sep = ""
#        ))
#      )
#      writeRes_labels(
#        res = res,
#        rseq = rseq,
#        thseq = thseq,
#        file.path(paste(foldername, "/labels", sep = ""))
#      )
#    }
#  })
#
#})
#
#toc()
#beep(sound = 2)
