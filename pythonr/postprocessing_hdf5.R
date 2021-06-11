# Title     : Postprocessing for Bayesian analysis
# Objective : Batch analysis for data from hdf5
# Adapted from: Griffié et al.
# Apated and written by: Saskia Kutz

post_fun <- function(newfolder, makeplot, superplot, separateplots, flipped) {
  source("./pythonr/package_list.R")
  source("./pythonr/exporting_hdf5.R")
  source("./pythonr/internal_postporcessing.R")
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

    filenames <- list.files(expname, pattern = '*.h5')

    res <- lapply(filenames, function(filename) {

      file <- H5Fopen(file.path(expname, filename))
      datafile <- h5read(file, 'data')
      pts <- datafile[, xcol:ycol]
      pts <- pts / 1000
      sds <- datafile[, sdcol]
      sds <- sds / 1000
      if (datasource == 'experiment') {
        names(pts)[1] <- "x"
        names(pts)[2] <- "y"
        xlim <- c(min(pts[, 1]), max(pts[, 1]))
        ylim <- c(min(pts[, 2]), max(pts[, 2]))
      }

      # read in r_vs_thresh
      r <- h5read(file, 'r_vs_thresh')
      r_attr <- h5readAttributes(file, 'r_vs_thresh')
      colnames(r) <- r_attr$scales
      rownames(r) <- r_attr$thresholds
      m <- as.matrix(r)
      cs <- colnames(r)
      thr <- rownames(r)

      which.maxm <- function(mat) {
        indcol <- rep(seq_len(ncol(mat)), each = nrow(mat))[which.max(mat)]
        indrow <- rep(seq_len(nrow(mat)), ncol(mat))[which.max(mat)]
        c(indrow, indcol)
      }

      best <- which.maxm(m)
      bestcs <- cs[best[2]]
      bestthr <- thr[best[1]]

      labelsbest <- h5read(file, paste0("labels/clusterscale", bestcs, "_thresh", bestthr, sep = ''))
      write_metadata_df(file, paste0("clusterscale", bestcs, "_thresh", bestthr, sep = ''), 'r_vs_thresh', 'best')

      # summaries
      cluster_area_density_labelcorr <- cluster_area_density(pts, labelsbest)
      summarytable <- cluster_area_density_labelcorr[[1]]

      write_df_hdf5(file, summarytable, "summarytable")
      write_metadata_df(file, names(summarytable), 'summarytable', 'colnames')

      if (length(labelsbest) == length(cluster_area_density_labelcorr[[2]])) {
        labelsbest <- cluster_area_density_labelcorr[[2]]
      }else {
        print("Corrected labels do not have the same length as the Bayesian labels!")
      }
      # TODO: propoer error message in software

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
        write_df_hdf5(file, trans_s, 'cluster-statistics')
        write_metadata_df(file, names(trans_s), 'cluster-statistics', 'colnames')
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
          plot_truelabels <- cluster_plot(pts, labelstrue, "True labels", flip = flipped)

          # Estimated labels plot
          plot_estimatedlabels <- cluster_plot(pts, labelsbest, "Estimated labels", flip = flipped)

          if (separateplots) {
            plot_save(plot_truelabels, expname, paste0(filename_base, "_truelabels"))
            plot_save(plot_estimatedlabels, expname, paste0(filename_base, "_estimatedlabels"))
          }

          plots_arrange(plot_truelabels, plot_estimatedlabels, 1, expname, paste0(filename_base, "_true_estimate_plot"))
        }else {
          plot_clustering <- cluster_plot(pts, labelsbest, "Clustering", sds, flip = flipped)
          plot_save(plot_clustering, expname, paste0(filename_base, "_Clustering"))
        }

        summary_plot(summarytable, paste0(filename_base, "_summarytable_plots"), exp_name = expname)
      }

      # H5Fclose(file)

      if (makeplot & superplot) {
        list(
          radii = clusterRadii(pts, labelsbest),
          nmols = summarytable$numDetectionsCluster,
          nclusters = nClusters(labelsbest),
          pclustered = percentageInCluster(labelsbest),
          totalmols = length(labelsbest),
          reldensity = reldensity(pts, labelsbest, summarytable$areasCluster, xlim, ylim),
          area = summarytable$areasCluster,
          density = summarytable$densitiesCluster,
          density_area = summarytable$densitiesCluster / summarytable$areasCluster,
          plots = plot_clustering
        )
      }else {
        list(
          radii = clusterRadii(pts, labelsbest),
          nmols = summarytable$numDetectionsCluster,
          nclusters = nClusters(labelsbest),
          pclustered = percentageInCluster(labelsbest),
          totalmols = length(labelsbest),
          reldensity = reldensity(pts, labelsbest, summarytable$areasCluster, xlim, ylim),
          area = summarytable$areasCluster,
          density = summarytable$densitiesCluster,
          density_area = summarytable$densitiesCluster / summarytable$areasCluster)
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


