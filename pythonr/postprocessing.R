# Title     : Postprocessing
# Objective : Postprocessing of Bayesian data
# Created by: Saskia Kutz
# Created on: 2020-07-30

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

    postprocessing_folder <- file.path(paste0(expname, "/postprocessing", sep =
      ""))
    dir.create(postprocessing_folder, showWarnings = F)
    all <- list.files(expname)
    dirnames <- all[file.info(file.path(paste0(expname, "/", all, sep = "")))$isdir]
    dirnames <- dirnames[dirnames != "postprocessing"]
    dirnames <- dirnames[dirnames != "postprocessing_ground_truth"]

    res <- lapply(dirnames, function(dirname) {
      foldername <- file.path(paste0(expname, "/", dirname, sep = ""))
      nfoldername <- file.path(paste0(nexpname, "/", dirname, sep = ""))

      data <- import_data(file.path(nfoldername))

      if (datasource == 'simulation') {
        pts <- data[, xcol:ycol]
        pts <- pts / 1000
        sds <- data[, sdcol]
        sds <- sds / 1000
      } else {
        pts <- data[, xcol:ycol]
        pts <- pts / 1000
        sds <- data[, sdcol]
        sds <- sds / 1000
        names(pts)[1] <- "x"
        names(pts)[2] <- "y"
        xlim <- c(min(pts[, 1]), max(pts[, 1]))
        ylim <- c(min(pts[, 2]), max(pts[, 2]))
      }

      if (process == "sequential") {
        r <- read.csv(file.path(paste0(nfoldername, "/r_vs_thresh.txt", sep = "")), header = FALSE, sep = "\t")

        m <- as.matrix(r)
        cs <- (m[1,])[-1]
        thr <- (m[, 1])[-1]
        m <- as.matrix(m[2:length(m[, 1]), 2:length(m[1,])])
      } else {
        r <- read.delim(file.path(paste0(nfoldername, "/r_vs_thresh.txt", sep = "")), header = T, sep = "\t")
        colnames(r) <- sub("X*", "", colnames(r))
        m <- as.matrix(r)
        cs <- colnames(m)
        thr <- rownames(m)
      }

      which.maxm <- function(mat) {
        indcol <- rep(seq_len(ncol(mat)), each = nrow(mat))[which.max(mat)]
        indrow <- rep(seq_len(nrow(mat)), ncol(mat))[which.max(mat)]
        c(indrow, indcol)
      }

      best <- which.maxm(m)
      bestcs <- cs[best[2]]
      bestthr <- thr[best[1]]
      bfile <- file.path(paste0(foldername, "/labels/clusterscale", bestcs, " thresh", bestthr, "labels.txt", sep = ""))
      nbfile <- bfile

      labelsbest <- strsplit(readLines(nbfile), ",")[[1]]

      # summaries
      cluster_area_density_labelcorr <- cluster_area_density(pts, labelsbest)
      summarytable <- cluster_area_density_labelcorr[[1]]
      if (length(labelsbest) == length(cluster_area_density_labelcorr[[2]])) {
        labelsbest <- cluster_area_density_labelcorr[[2]]
      }else {
        print("Corrected labels do not have the same length as the Bayesian labels!")
      }

      wfile <- file.path(paste0(nfoldername, "/summary.txt", sep = ""))
      if (datasource == "simulation") {
        cat(
          "The best: clusterscale", bestcs, " thresh", bestthr,
          "labels.txt\nNumber of clusters: ", nClusters(labelsbest),
          "\nPercentage in clusters: ", percentageInCluster(labelsbest),
          "%\nMean number of molecules per cluster: ", nMolsPerCluster(labelsbest),
          "\nMean area per cluster: ", mean(summarytable$areasCluster),
          " nm²\nMean density per cluster: ", mean(summarytable$densitiesCluster),
          "\nMean radius: ", mean(clusterRadii(pts, labelsbest)), " nm (simulation)",
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

      s <- clusterStatistics(pts, labelsbest)
      if (!is.null(s) & s[1] != -1) {
        wfile <- file.path(paste0(nfoldername, "/cluster-statistics.txt", sep = ""))
        cat("x,y,sd,nmol\n", file = wfile)
        for (i in 1:dim(s)[2]) {
          cat(s[, 1],
              sep = ",",
              append = TRUE,
              file = wfile
          )
          cat("\n", append = TRUE, file = wfile)
        }
      }

      if (makeplot) {
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
            plot_save(plot_truelabels, nfoldername, "truelabels")
            plot_save(plot_estimatedlabels, nfoldername, "estimatedlabels")
          }

          plots_arrange(plot_truelabels, plot_estimatedlabels, 1, nfoldername, "true_estimate_plot")
        }else {
          plot_clustering <- cluster_plot(pts, labelsbest, "Clustering", sds, "experiment")
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

    if (makeplot & superplot)
      cluster_superplot(res, dirnames, postprocessing_folder, "ROIs_together")

    hist_plot(res, postprocessing_folder)

  })
}


