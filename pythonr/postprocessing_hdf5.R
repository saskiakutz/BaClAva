# Title     : postprocessing for Bayesian analysis
# Objective : hdf5 datasource
# Created by: saskia-admin
# Created on: 2021-01-27

post_fun <- function(newfolder, makeplot, superplot, separateplots) {
  source("./pythonr/internal.R")
  source("./pythonr/plot_functions.R")
  l_ply(newfolder, function(expname) {
    nexpname <- expname

    r <- readLines(con = file.path(paste0(nexpname, "/run_config.txt", sep = "")))

    get <- function(type) {
      i <- grep(type, r)
      strsplit(r[i], "=")[[1]][2]
    }

    datasource <- get("datasource")

    if (datasource == 'simulation') {
      xlim <- c(as.numeric(get("roixmin")), as.numeric(get("roixmax")))
      ylim <- c(as.numeric(get("roiymin")), as.numeric(get("roiymax")))
    }
    xcol <- as.numeric(get("xcol"))
    ycol <- as.numeric(get("ycol"))
    sdcol <- as.numeric(get("sdcol"))

    computation <- as.numeric(get("parallel"))
    if (computation == 0) {
      process <- "sequential"
    } else {
      process <- "parallel"
    }

    # all <- list.files(expname)
    # dirnames <- all[file.info(file.path(paste0(expname, "/", all, sep = "")))$isdir]
    # dirnames <- dirnames[dirnames != "postprocessing"]
    # dirnames <- dirnames[dirnames != "postprocessing_ground_truth"]
    filenames <- list.files(expname, pattern = '*.h5')


    res <- lapply(filenames, function(filename) {
      # foldername <- file.path(paste0(expname, "/", dirname, sep = ""))
      # nfoldername <- file.path(paste0(nexpname, "/", dirname, sep = ""))

      file <- H5Fopen(file.path(expname, filename))

      if (datasource == 'simulation') {
        datafile <- h5read(file, 'data')
        pts <- datafile[, xcol:ycol]
        pts <- pts / 1000
        sds <- datafile[, sdcol]
        sds <- sds / 1000
      } else {
        datafile <- h5read(file, 'data')
        pts <- datafile[, xcol:ycol]
        pts <- pts / 1000
        sds <- datafile[, sdcol]
        sds <- sds / 1000
        names(pts)[1] <- "x"
        names(pts)[2] <- "y"
        xlim <- c(min(pts[, 1]), max(pts[, 1]))
        ylim <- c(min(pts[, 2]), max(pts[, 2]))
      }

      #if (process == "sequential") {
      r <- h5read(file, 'r_vs_thresh')
      r_attr <- h5readAttributes(file, 'r_vs_thresh')
      colnames(r) <- r_attr$scales
      rownames(r) <- r_attr$thresholds
      m <- as.matrix(r)
      cs <- colnames(r)
      thr <- rownames(r)

      # } else {
      #   r <- read.delim(file.path(paste0(nfoldername, "/r_vs_thresh.txt", sep = "")), header = T, sep = "\t")
      #   colnames(r) <- sub("X*", "", colnames(r))
      #   m <- as.matrix(r)
      #   cs <- colnames(m)
      #   thr <- rownames(m)
      # }

      which.maxm <- function(mat) {
        indcol <- rep(seq_len(ncol(mat)), each = nrow(mat))[which.max(mat)]
        indrow <- rep(seq_len(nrow(mat)), ncol(mat))[which.max(mat)]
        c(indrow, indcol)
      }

      best <- which.maxm(m)
      bestcs <- cs[best[2]]
      bestthr <- thr[best[1]]

      labelsbest <- h5read(file, paste0("labels/clusterscale", bestcs, "_thresh", bestthr, sep = ''))
      r_thresh <- H5Dopen(file, 'r_vs_thresh')
      h5writeAttribute(r_thresh, attr = paste0("clusterscale", bestcs, "_thresh", bestthr, sep = ''), name = 'best')
      H5Dclose(r_thresh)

      # summaries
      cluster_area_density_labelcorr <- cluster_area_density(pts, labelsbest)
      summarytable <- cluster_area_density_labelcorr[[1]]
      if (length(labelsbest) == length(cluster_area_density_labelcorr[[2]])) {
        labelsbest <- cluster_area_density_labelcorr[[2]]
      }else {
        print("Corrected labels do not have the same length as the Bayesian labels!")
      }

      # TODO: summary export to hdf5 file
      filename_base <- str_split(filename, "\\.")[[1]][1]
      wfile <- file.path(expname, paste0(filename_base, "_summary.txt"))
      if (datasource == "simulation") {
        cat(
          "The best: clusterscale", bestcs, "_thresh", bestthr,
          "labels.txt\nNumber of clusters: ", nClusters(labelsbest),
          "\nPercentage in clusters: ", percentageInCluster(labelsbest),
          "%\nMean number of molecules per cluster: ", nMolsPerCluster(labelsbest),
          "\nMean area per cluster: ", mean(summarytable$areasCluster),
          " nm²\nMean density per cluster: ", mean(summarytable$densitiesCluster),
          "\nMean radius: ", mean(clusterRadii(pts, labelsbest)), " nm (simulation)",
          sep = "",
          file = wfile

        )
      } else {
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

      s <- clusterStatistics(pts, labelsbest)
      trans_s <- t(s)
      colnames(trans_s) <- c("x", "y", "sd", "nmol")
      if (!is.null(s) & s[1] != -1) {
        tryCatch(
        {
          h5write(trans_s, file, "cluster-statistics") },
          error = function(e) {
            h5delete(file, "cluster-statistics")
            h5write(trans_s, file, "cluster-statistics")
          }
        )
        ds <- H5Dopen(file, 'cluster-statistics')
        h5writeAttribute(ds, attr = names(trans_s), name = 'colnames')
        H5Dclose(ds)
      }

      if (makeplot == TRUE) {
        if ("clusterID" %in% colnames(data) & !superplot) {
          labelstrue <- sapply(as.numeric(data[, 4]), function(n) {
            if (n == 0)
              paste0(runif(1))
            else {
              paste0(n)
            }
          })

          # True labels plot
          plot_truelabels <- cluster_plot(pts, labelstrue, "True labels")

          # Estimated labels plot
          plot_estimatedlabels <- cluster_plot(pts, labelsbest, "Estimated labels")

          if (separateplots) {
            plot_save(plot_truelabels, expname, "truelabels")
            plot_save(plot_estimatedlabels, expname, "estimatedlabels")
          }

          plots_arrange(plot_truelabels, plot_estimatedlabels, 1, expname, "true_estimate_plot")
        }else {
          plot_clustering <- cluster_plot(pts, labelsbest, "Clustering", sds, "experiment")
          plot_save(plot_clustering, expname, "Clustering")
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
      }else {
        list(
          radii = clusterRadii(pts, labelsbest),
          nmols = molsPerCluster(labelsbest),
          nclusters = nClusters(labelsbest),
          pclustered = percentageInCluster(labelsbest),
          totalmols = length(labelsbest),
          reldensity = reldensity(pts, labelsbest, summarytable$areasCluster, xlim, ylim),
          area = summarytable$areasCluster,
          density = summarytable$densitiesCluster)
      }
    })

    # statistics over all datasets
    postprocessing_folder <- file.path(paste0(expname, "/postprocessing", sep =
      ""))
    dir.create(postprocessing_folder, showWarnings = F)
    if (makeplot & superplot)
      cluster_superplot(res, filenames, postprocessing_folder, "ROIs_together")

    hist_plot(res, postprocessing_folder, makeplot)
    h5closeAll()
  })
}


