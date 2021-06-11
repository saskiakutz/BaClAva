# Title     : Simulation
# Objective : with hdf5 import
# Adapted from: Griffié et al.
# Adapted and written by: Saskia Kutz

# BiocManager::install("rhdf5")
if (!require(pacman, quietly = TRUE))
  install.packages("pacman")
pacman::p_load("rhdf5")

simulation_fun <- function(newfolder, nclusters, molspercluster, background, xlim, ylim, gammaparams, nsim, sdcluster, ab = NA) {

  if (length(sdcluster) == 1) {
    sdcluster <- rep(sdcluster, nclusters)
  }
  else nclusters <- length(sdcluster)

  if (length(ab) == 1) {
    ab <- FALSE
  }else {
    fa <- ab[1]
    fb <- ab[2]
    ab <- TRUE
  }
  multimer <- 1

  sapply(1:nsim, function(expi) {

    centre_calculation <- function(xlim, ylim) {
      centre <- c(runif(1, min = xlim[1], max = xlim[2]),
                  runif(1, min = ylim[1], max = ylim[2]))
    }

    centeredpts <- function(n, centre, sdcluster) {
      cbind(rnorm(n, mean = centre[1], sd = sdcluster), rnorm(n, mean = centre[2], sd = sdcluster))
    }

    ptsc <- NULL
    lc <- NULL
    center_tmp <- NULL

    for (i in 1:nclusters) {
      centre <- centre_calculation(xlim, ylim)

      if (length(center_tmp[, 1]) > 0) {
        while (sum(
          sqrt(abs(center_tmp[, 1] - centre[1])^2 + abs(center_tmp[, 2] - centre[2])^2) <= 2 * sdcluster[1])) {
          centre <- centre_calculation(xlim, ylim)
        }
      }

      center_tmp <- rbind(center_tmp, centre)

      if (multimer <= 1) {
        lc <- c(lc, rep(i, molspercluster))
        print(sdcluster[i])
        ptsc <- rbind(ptsc, centeredpts(molspercluster, centre, sdcluster[i]))
      } else {
        if (nclusters > 0) {
          lc <- c(lc, rep(i, multimer))
          ptsc <- rbind(ptsc, matrix(rep(centre, each = multimer), ncol = 2))
        }
      }

    }

    sds <- rgamma(dim(ptsc)[1], gammaparams[1], gammaparams[2])
    noise <- cbind(rnorm(dim(ptsc)[1]), rnorm(dim(ptsc)[1]))
    ptsn <- ptsc + noise * sds

    inside <- (ptsn[, 1] >= xlim[1]) &
      (ptsn[, 1] <= xlim[2]) &
      (ptsn[, 2] >= ylim[1]) &
      (ptsn[, 2] <= ylim[2])
    ptsn <- ptsn[inside,]
    lc <- lc[inside]
    sds <- sds[inside]
    npts <- dim(ptsn)[1]
    if (multimer <= 1) {
      nb <- ceiling(npts * background / (1 - background))
    }
    else {
      nb <- nmols - nclusters ##not dealing with the very unlikely case that all multimers are moved off the ROI due to localisation imprecision
    }

    if (!ab) ptsb <- cbind(runif(nb, min = xlim[1], max = xlim[2]), runif(nb, min = ylim[1], max = ylim[2]))
    else {
      xpts <- rbeta(nb, fa, fb) * diff(xlim) + xlim[1]
      ptsb <- cbind(xpts[1:nb], runif(nb, min = ylim[1], max = ylim[2]))
    }
    pts <- rbind(ptsn, ptsb)
    labels <- 1:(dim(pts)[1]); labels[seq_along(lc)] <- lc
    sdsb <- rgamma(dim(pts)[1] - length(lc), gammaparams[1], gammaparams[2])
    sds <- c(sds, sdsb)

    data <- data.frame(pts, sds, labels)
    colnames(data) <- c("x", "y", "sd", "clusterID")

    # dir.create(file.path(paste0(newfolder, "/", expi, sep = "")), showWarnings = F)
    # write.csv(data, file = file.path(paste0(newfolder, "/", expi, "/data.txt", sep = "")), row.names = FALSE, quote = FALSE)

    filename <- file.path(newfolder, paste0("simulation_", expi, ".h5", sep = ""))

    h5createFile(filename)

    tryCatch(
    {
      h5write(data, filename, "data")
    },
      error = function(e) {
        h5delete(filename, "data")
        h5write(data, filename, "data") },
      warning = function(w) {
        h5delete(filename, "data")
        h5write(data, filename, "data")
      }
    )

    file = H5Fopen(filename)
    did <- H5Dopen(file, "data")
    h5writeAttribute(did, attr = names(data), name = "colnames")

    H5Dclose(did)
    H5close()
    h5closeAll()
  })
}

