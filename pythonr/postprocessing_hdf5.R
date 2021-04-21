# Title     : postprocessing for Bayesian analysis
# Objective : hdf5 datasource
# Created by: saskia-admin
# Created on: 2021-01-27

post_fun <- function(newfolder, makeplot, superplot, separateplots) {
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
      # r_thresh <- H5Dopen(file, 'r_vs_thresh')
      # h5writeAttribute(r_thresh, attr = paste0("clusterscale", bestcs, "_thresh", bestthr, sep = ''), name = 'best')
      # H5Dclose(r_thresh)

      # summaries
      cluster_area_density_labelcorr <- cluster_area_density(pts, labelsbest)
      summarytable <- cluster_area_density_labelcorr[[1]]

      # tryCatch(
      # {
      #   h5write(summarytable, file, "summarytable") },
      #   error = function(e) {
      #     h5delete(file, "cluster-statistics")
      #     h5write(summarytable, file, "cluster-statistics")
      #   }
      # )
      write_df_hdf5(file, summarytable, "summarytable")
      write_metadata_df(file, names(summarytable), 'summarytable', 'colnames')
      # ds <- H5Dopen(file, 'summarytable')
      # h5writeAttribute(ds, attr = names(summarytable), name = 'colnames')
      # H5Dclose(ds)

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
        # tryCatch(
        # {
        #   h5write(trans_s, file, "cluster-statistics") },
        #   error = function(e) {
        #     h5delete(file, "cluster-statistics")
        #     h5write(trans_s, file, "cluster-statistics")
        #   }
        # )
        write_metadata_df(file, names(trans_s), 'cluster-statistics', 'colnames')
        # ds <- H5Dopen(file, 'cluster-statistics')
        # h5writeAttribute(ds, attr = names(trans_s), name = 'colnames')
        # H5Dclose(ds)
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
            plot_save(plot_truelabels, expname, paste0(filename_base, "truelabels"))
            plot_save(plot_estimatedlabels, expname, paste0(filename_base, "estimatedlabels"))
          }

          plots_arrange(plot_truelabels, plot_estimatedlabels, 1, expname, paste0(filename_base, "true_estimate_plot"))
        }else {
          plot_clustering <- cluster_plot(pts, labelsbest, "Clustering", sds, "experiment")
          plot_save(plot_clustering, expname, paste0(filename_base, "Clustering"))
        }

        # plot summarytable data ("numDetectionsCluster", "areasCluster", "densitiesCluster")
        plot_num_area <- ggplot(summarytable, aes(x = numDetectionsCluster, y = areasCluster)) + geom_point()
        plot_save(plot_num_area, expname, paste0(filename_base, "numDetectionsCluster_vs_areasCluster"))
        plot_num_density <- ggplot(summarytable, aes(x = numDetectionsCluster, y = densitiesCluster)) + geom_point()
        plot_save(plot_num_density, expname, paste0(filename_base, "numDetectionsCluster_vs_densitiesCluster"))
        plot_area_density <- ggplot(summarytable, aes(x = areasCluster, y = densitiesCluster)) + geom_point()
        plot_save(plot_area_density, expname, paste0(filename_base, "areasCluster_vs_densitiesCluster"))
      }

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
          density = summarytable$densitiesCluster)
      }
      H5Fclose(file)
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


