post_fun <- function() {
  source("internal.R")
  source("plot_functions.R")
  l_ply(newfolder, function(expname) {
    nexpname = expname

  })
}

# postprocessing ----------------------------------------------------------

l_ply(foldernames, function(expname) {
  # best parameter set ----------------------------------------------------

  if (length(grep("skeleton", r)) == 0) {
    skeleton = FALSE
  } else {
    skeleton = as.logical(as.numeric(get("skeleton")))
  }

  if (skeleton) {
    nexpname = paste0("R_", expname, sep = "")
    dir.create(file.path(nexpname))
    file.copy(file.path(paste0(expname, "/config.txt", sep = "")),
              paste0(nexpname, "/config.txt", sep = ""))
    file.copy(file.path(paste0(expname, "/sim_params.txt", sep = "")),
              paste0(nexpname, "/sim_params.txt", sep = ""))
  }

  model = get("model")
  {
  if (model == "Gaussian(prec)") {
    datasource = get("datasource")
    if (datasource == "simulation") {
      xlim = as.v(get("xlim"))
      ylim = as.v(get("ylim"))
    }
    histbins = as.v(get("histbins"))
    histvalues = as.v(get("histvalues"))
    if (length(grep("pbackground", r)) == 0 |
      length(grep("alpha", r)) == 0) {
      useplabel = FALSE
      pb = NULL
      alpha = NULL
    }
    else {
      useplabel = TRUE

      pb = as.numeric(get("pbackground"))
      alpha = as.numeric(get("alpha"))
    }
    if (length(grep("bestonly", r)) == 0)
      bestonly = FALSE
    else
      bestonly = as.numeric(get("bestonly")) > 0
    if (length(grep("rseq", r)) == 0)
      rseq = seq(10, 200, by = 5)
    else {
      rparams = as.v(get("rseq"))
      rseq = seq(rparams[1], rparams[2], by = rparams[3])
    }
    if (length(grep("thseq", r)) == 0)
      thseq = seq(5, 500, by = 5)
    else {
      thparams = as.v(get("thseq"))
      thseq = seq(thparams[1], thparams[2], by = thparams[3])
    }
    if (length(grep("parallel", r)) == 0)
      process = "sequential"
    else {
      process = as.numeric(get("parallel"))
      if (process == 0) {
        process = "sequential"
      }
      else {
        process = "parallel"
      }
    }
  }
  else {
    stop("Haven't implemented anything else!")
  }
}


  if (length(grep("makeplot", r)) == 0) {
    makeplot = FALSE
  } else {
    makeplot = as.logical(as.numeric(get("makeplot")))
  }
  if (length(grep("superplot", r)) == 0) {
    superplot = FALSE
  } else {
    superplot = as.logical(as.numeric(get("superplot")))
  }
  if (length(grep("separateplots", r)) == 0) {
    separateplots = FALSE
  } else {
    separateplots = as.logical(as.numeric(get("separateplots")))
  }

  postprocessing_folder = file.path(paste0(expname, "/postprocessing", sep =
    ""))
  dir.create(postprocessing_folder, showWarnings = F)
  all = list.files(expname)
  dirnames = all[file.info(file.path(paste0(expname, "/", all, sep = "")))$isdir]
  dirnames = dirnames[dirnames != "postprocessing"]
  dirnames = dirnames[dirnames != "postprocessing_ground_truth"]

  res = lapply(dirnames, function(dirname) {
    foldername = file.path(paste0(expname, "/", dirname, sep = ""))
    nfoldername = file.path(paste0(nexpname, "/", dirname, sep = ""))

    if (skeleton) {
      dir.create(nfoldername)
      file.copy(file.path(paste0(foldername, "/data.txt", sep = "")),
                file.path(paste0(nfoldername, "/data.txt", sep = "")))
    }

    data = import_data(file.path(nfoldername))

    if (datasource == "simulation") {
      pts = data[, 1:2]
      sds = data[, 3]
    } else {
      pts = data[, 1:2]
      pts = pts / 1000
      sds = data[, 4]
      sds = sds / 1000
      names(pts)[1] = "x"
      names(pts)[2] = "y"
      xlim = c(min(pts[, 1]), max(pts[, 1]))
      ylim = c(min(pts[, 2]), max(pts[, 2]))
    }


    if (skeleton) {
      file.copy(file.path(paste0(
        foldername, "/r_vs_thresh.txt", sep = ""
      )),
                file.path(paste0(
                  nfoldername, "/r_vs_thresh.txt", sep = ""
                )))
    }
    if (process == "sequential") {
      r = read.csv(file.path(paste0(
        nfoldername, "/r_vs_thresh.txt", sep = ""
      )),
                   header = FALSE, sep = "\t")

      m = as.matrix(r)
      cs = (m[1,])[-1]
      thr = (m[, 1])[-1]
      m = as.matrix(m[2:length(m[, 1]), 2:length(m[1,])])
    } else {
      r = read.delim(file.path(paste0(
        nfoldername, "/r_vs_thresh.txt", sep = ""
      ))
        , header = T, sep = "\t")
      colnames(r) <- sub("X*", "", colnames(r))
      # rownames(r) <- r[,1]
      # r[,1] <- NULL
      m = as.matrix(r)
      cs = colnames(m)
      thr = rownames(m)
    }

    which.maxm <- function(mat) {
      indcol <- rep(1:ncol(mat), each = nrow(mat))[which.max(mat)]
      indrow <- rep(1:nrow(mat), ncol(mat))[which.max(mat)]
      c(indrow, indcol)
    }

    best = which.maxm(m)
    bestcs = cs[best[2]]
    bestthr = thr[best[1]]
    bfile = file.path(
      paste0(
        foldername,
        "/labels/clusterscale",
        bestcs,
        " thresh",
        bestthr,
        "labels.txt",
        sep = ""
      )
    )
    nbfile = bfile

    if (skeleton) {
      dir.create(paste0(nfoldername, "/labels", sep = ""))
      nbfile = file.path(
        paste0(
          nfoldername,
          "/labels/clusterscale",
          bestcs,
          " thresh",
          bestthr,
          "labels.txt",
          sep = ""
        )
      )
      file.copy(bfile, nbfile)
    }
    labelsbest = strsplit(readLines(nbfile), ",")[[1]]


    ##Some summaries
    cluster_area_density_labelcorr = cluster_area_density(pts, labelsbest)
    summarytable = cluster_area_density_labelcorr[[1]]
    if (length(labelsbest) == length(cluster_area_density_labelcorr[[2]])) {
      labelsbest = cluster_area_density_labelcorr[[2]]
    }else {
      print("Corrected labels does not have the same length as the Bayesian labels!")
    }


    wfile = file.path(paste0(nfoldername, "/summary.txt", sep = ""))
    if (datasource == "simulation") {
      cat(
        "The best: clusterscale",
        bestcs,
        " thresh",
        bestthr,
        "labels.txt\nNumber of clusters:",
        nClusters(labelsbest),
        "\nPercentage in clusters: ",
        percentageInCluster(labelsbest),
        "%\nMean number of molecules per cluster: ",
        nMolsPerCluster(labelsbest),
        "\nMean area per cluster: ",
        mean(summarytable$areasCluster),
        " nm²",
        "\nMean density per cluster: ",
        mean(summarytable$densitiesCluster),
        "\nMean radius: ",
        mean(clusterRadii(pts, labelsbest)),
        " nm",
        sep = "",
        file = wfile
      )
    }else {
      cat(
        "The best: clusterscale",
        bestcs,
        " thresh",
        bestthr,
        "labels.txt\nNumber of clusters:",
        nClusters(labelsbest),
        "\nPercentage in clusters: ",
        percentageInCluster(labelsbest),
        "%\nMean number of molecules per cluster: ",
        nMolsPerCluster(labelsbest),
        "\nMean area per cluster: ",
        mean(summarytable$areasCluster),
        " µm²",
        "\nMean density per cluster: ",
        mean(summarytable$densitiesCluster),
        "\nMean radius: ",
        mean(clusterRadii(pts, labelsbest)),
        " µm",
        sep = "",
        file = wfile
      )
    }

    s = clusterStatistics(pts, labelsbest)
    if (!is.null(s) & s[1] != -1) {

      wfile = file.path(paste0(nfoldername,
                               "/cluster-statistics.txt", sep = ""))
      cat("x,y,sd,nmol\n", file = wfile)
      for (i in 1:dim(s)[2]) {
        cat(s[, i],
            sep = ",",
            append = TRUE,
            file = wfile)
        cat("\n", append = TRUE, file = wfile)
      }
    }

    if (makeplot) {
      if ("clusterID" %in% colnames(data) & !superplot) {
        labelstrue = sapply(as.numeric(data[, 4]), function(n) {
          if (n == 0)
            paste0(runif(1))
          else {
            paste0(n)
          }
        })

        # True Labels plot
        plot_truelabels = cluster_plot(pts, labelstrue, "True labels")

        if (separateplots)
          plot_save(plot_truelabels, nfoldername, "truelabels")


        # Estimated labels plot
        plot_estimatedlabels = cluster_plot(pts, labelsbest, "Estimated labels")

        if (separateplots)
          plot_save(plot_estimatedlabels, nfoldername, "estimatedlabels")

        plots_arrange(plot_truelabels,
                      plot_estimatedlabels,
                      1,
                      nfoldername,
                      "true_estimate_plot")


      } else {
        plot_clustering = cluster_plot(pts, labelsbest, "Clustering", sds, "experiment")
        plot_save(plot_clustering, nfoldername, "Clustering")

      }
    }

    if (makeplot & superplot) {

      list(
        radii = clusterRadii(pts, labelsbest),
        nmols = molsPerCluster(labelsbest),
        nclusters = nClusters(labelsbest),
        pclustered = percentageInCluster(labelsbest),
        totalmols = length(labelsbest),
        reldensity = reldensity(pts, labelsbest, summarytable$areasCluster, xlim, ylim),
        area = summarytable$areasCluster,
        density = summarytable$densitiesCluster,
        plots = plot_clustering
      )

    } else {

      list(
        radii = clusterRadii(pts, labelsbest),
        nmols = molsPerCluster(labelsbest),
        nclusters = nClusters(labelsbest),
        pclustered = percentageInCluster(labelsbest),
        totalmols = length(labelsbest),
        reldensity = reldensity(pts, labelsbest, summarytable$areasCluster, xlim, ylim),
        area = summarytable$areasCluster,
        density = summarytable$densitiesCluster
      )

    }

  })

  # statistics over all datasets --------------------------------------------

  if (makeplot & superplot)
    cluster_superplot(res, dirnames, postprocessing_folder, "ROIs_together")


  hist_plot(res, postprocessing_folder)
  # hist_plot_fix_limits(res, nexpname, 0,175,0,110)

})

beep(sound = 2)
