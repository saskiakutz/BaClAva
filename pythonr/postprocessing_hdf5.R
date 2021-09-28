# Title     : Postprocessing for Bayesian analysis
# Objective : Batch analysis for data from hdf5
# Adapted from: Griffié et al.
# Adapted and written by: Saskia Kutz

post_fun <- function(newfolder, meter_unit, makeplot, storage, superplot, separateplots, flipped) {
  source("./pythonr/package_list.R")
  source("./pythonr/exporting_hdf5.R")
  source("./pythonr/internal_postporcessing.R")
  source("./pythonr/plot_functions.R")
  source("./pythonr/exporting_csv.R")
  plyr::l_ply(newfolder, function(expname) {
    nexpname <- expname

    run_con <- readLines(con = file.path(paste0(nexpname, "/run_config.txt", sep = "")))

    get <- function(type, file_name) {
      i <- grep(type, file_name)
      strsplit(file_name[i], "=")[[1]][2]
    }

    datasource <- get("datasource", run_con)
    cluster_id <- list()

    if (datasource == 'simulation') {
      sim_con <- readLines(con = file.path(paste0(nexpname, "/sim_parameters.txt", sep = "")))
      x_limit <- c(as.numeric(get("roixmin", sim_con)), as.numeric(get("roixmax", sim_con)))
      y_limit <- c(as.numeric(get("roiymin", sim_con)), as.numeric(get("roiymax", sim_con)))
    }

    xcol <- as.numeric(get("xcol", run_con))
    ycol <- as.numeric(get("ycol", run_con))
    sdcol <- as.numeric(get("sdcol", run_con))

    computation <- as.numeric(get("parallel=", run_con))
    if (computation == 0) {
      process <- "sequential"
    } else {
      process <- "parallel"
    }



    filenames <- list.files(expname, pattern = '*.h5')

    res <- lapply(filenames, function(filename) {

      file <- rhdf5::H5Fopen(file.path(expname, filename))
      datafile <- rhdf5::h5read(file, 'data')
      pts <- datafile[, xcol:ycol]
      sds <- datafile[, sdcol]

      if (meter_unit == 'um'){
        pts <- pts / 1000
        sds <- sds / 1000
      }

      if (datasource == 'experiment') {
        names(pts)[1] <- "x"
        names(pts)[2] <- "y"
        x_limit <- c(min(pts[, 1]), max(pts[, 1]))
        y_limit <- c(min(pts[, 2]), max(pts[, 2]))
      }else{
        cluster_id <- datafile[, 4]
      }

      # read in r_vs_thresh
      r <- rhdf5::h5read(file, 'r_vs_thresh')
      r_attr <- rhdf5::h5readAttributes(file, 'r_vs_thresh')
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

      labelsbest <- rhdf5::h5read(file, paste0("labels/clusterscale", bestcs, "_thresh", bestthr, sep = ''))
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

      # TODO: summary export to hdf5 file and adjustment to nm or um
      filename_base <- stringr::str_split(filename, "\\.")[[1]][1]
      wfile <- file.path(expname, paste0(filename_base, "_summary.txt"))
      if (datasource == "simulation") {
        cat(
          "The best: clusterscale", bestcs, "_thresh", bestthr,
          "labels.txt\nLength unit: ", meter_unit,
          "\nNumber of clusters: ", nClusters(labelsbest),
          "\nPercentage in clusters: ", percentageInCluster(labelsbest),
          "%\nMean number of molecules per cluster: ", nMolsPerCluster(labelsbest),
          "\nMean area per cluster: ", mean(summarytable$areasCluster),
          " nm² or um²\nMean density per cluster: ", mean(summarytable$densitiesCluster),
          "\nMean radius: ", mean(clusterRadii(pts, labelsbest)), " nm or µm",
          sep = "",
          file = wfile

        )
      } else {
        cat(
          "The best: clusterscale",
          bestcs,
          " thresh",
          bestthr,
          "labels.txt\nlength unit: ", meter_unit,
          "\nNumber of clusters:",
          nClusters(labelsbest),
          "\nPercentage in clusters: ",
          percentageInCluster(labelsbest),
          "%\nMean number of molecules per cluster: ",
          nMolsPerCluster(labelsbest),
          "\nMean area per cluster: ",
          mean(summarytable$areasCluster),
          " µm² or nm²",
          "\nMean density per cluster: ",
          mean(summarytable$densitiesCluster),
          "\nMean radius: ",
          mean(clusterRadii(pts, labelsbest)),
          " µm or nm",
          sep = "",
          file = wfile
        )
      }

      s <- clusterStatistics(pts, labelsbest)
      trans_s <- t(s)
      colnames(trans_s) <- c(paste0("x_", meter_unit), paste0("y_", meter_unit), paste0("sd_", meter_unit), "nmol")
      if (!is.null(s) & s[1] != -1) {
        write_df_hdf5(file, trans_s, 'cluster-statistics')
        write_metadata_df(file, colnames(trans_s), 'cluster-statistics', 'colnames')
      }

      if (makeplot == TRUE) {

        if (length(cluster_id) > 0 & !superplot) {
          labelstrue <- sapply(as.numeric(cluster_id), function(n) {
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
            plot_save(plot_truelabels, expname, paste0(filename_base, "_truelabels"), storage_opt = storage)
            plot_save(plot_estimatedlabels, expname, paste0(filename_base, "_estimatedlabels"), storage_opt = storage)
          }

          plots_arrange(plot_truelabels, plot_estimatedlabels, 1, expname, paste0(filename_base, "_true_estimate_plot"), storage_ends = storage)
        }else {

          plot_clustering <- cluster_plot(pts, labelsbest, paste0("Clustering: ", filename_base), sds, flip = flipped)
          plot_save(plot_clustering, expname, paste0(filename_base, "_Clustering"), storage_opt = storage)
        }
#
#         # summary_plot(summarytable, paste0(filename_base, "_summarytable_plots"), exp_name = expname)
      }

      # H5Fclose(file)

      if (makeplot & superplot) {
        list(
          radii = clusterRadii(pts, labelsbest),
          nmols = summarytable$numDetectionsCluster,
          nclusters = nClusters(labelsbest),
          pclustered = percentageInCluster(labelsbest),
          totalmols = length(labelsbest),
          reldensity = relative_density(pts, labelsbest, summarytable$areasCluster, x_limit, y_limit),
          area = summarytable$areasCluster,
          density = summarytable$densitiesCluster,
          density_area = summarytable$densitiesCluster / summarytable$areasCluster,
          plots = plot_clustering,
          id = filename_base
        )
      }else {
        list(
          radii = clusterRadii(pts, labelsbest),
          nmols = summarytable$numDetectionsCluster,
          nclusters = nClusters(labelsbest),
          pclustered = percentageInCluster(labelsbest),
          totalmols = length(labelsbest),
          reldensity = relative_density(pts, labelsbest, summarytable$areasCluster, x_limit, y_limit),
          area = summarytable$areasCluster,
          density = summarytable$densitiesCluster,
          density_area = summarytable$densitiesCluster / summarytable$areasCluster,
          id = filename_base
        )
      }
    })

    # statistics over all datasets
    postprocessing_folder <- file.path(paste0(expname, "/postprocessing", sep =
      ""))
    dir.create(postprocessing_folder, showWarnings = F)
    if (makeplot & superplot)
      cluster_superplot(res, filenames, postprocessing_folder, "ROIs_together", stor_ends = storage)

    creating_tibble(res, postprocessing_folder)

    hist_plot(res, postprocessing_folder, makeplot, storage_ends = storage)
    rhdf5::h5closeAll()
  })
}


