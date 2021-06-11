# Title     : Postprocessing functions
# Objective : Functions for calculations in the postprocessing step
# Written by: Saskia Kutz

cluster_area_density <-
  function(coords, clusterIndices) {
    #based on function by Jeremy Pike

    numDimensions <- dim(coords)[2]
    if (numDimensions != 2) {
      stop('Coordinates should be 2D')
    }

    # check coords and clusterIndices have the same number of detections
    numDetections <- dim(coords)[1]
    if (numDetections != length(clusterIndices)) {
      stop('coords and clusterIndices should have the same length')
    }


    # find indices of all clusters
    clusterIndices_num <- as.numeric(clusterIndices)
    clusterIndicesUnique <-
      sort(unique(clusterIndices_num[duplicated(clusterIndices_num)]))
    numClusters <- length(clusterIndicesUnique)

    # data frame to hold per cluster statistics (fill with zeros)
    clustStats <-
      data.frame(matrix(0, nrow = numClusters, ncol = 5))
    colnames(clustStats) <-
      c("numDetectionsCluster",
        "areasCluster",
        "densitiesCluster",
        "meanX",
        "meanY")

    if (numClusters > 0) {
      for (i in seq(1, numClusters)) {
        # cluster coordinates
        cluster_par <- clusterIndicesUnique[i]
        coordsCluster <- coords[clusterIndices == cluster_par,]

        if (var(coordsCluster$x) == 0 ||
          var(coordsCluster$y) == 0 ||
          length(coordsCluster$x) < 3) {
          j <- 1
          maxlabel <- max(as.numeric(clusterIndices))
          for (search_index in seq(1, length(clusterIndices))) {
            if (clusterIndices[search_index] == cluster_par) {
              clusterIndices[search_index] <- as.character(maxlabel + j)
              j <- j + 1
            }
          }
        }else {
          tryCatch(
          {
            if (sum(clusterIndices == cluster_par) > 2) {
              # mean coordinates for each dimension
              clustStats$meanX[i] <- mean(coordsCluster[, 1])
              clustStats$meanY[i] <- mean(coordsCluster[, 2])

              # find number of detections in cluster
              clustStats$numDetectionsCluster[i] <-
                sum(clusterIndices == cluster_par)

              #calculate convex hull
              ch <- convhulln(coordsCluster, options = "FA")

              # get cluster area and densities.
              # Used geometry library to calculate convex hulls.
              clustStats$areasCluster[i] <- ch$vol #area of the 2D hull
              clustStats$densitiesCluster[i] <-
                clustStats$numDetectionsCluster[i] / clustStats$areasCluster[i]
            }
            else {
              j <- 1
              maxlabel <- max(as.numeric(clusterIndices))
              for (search_index in seq(1, length(clusterIndices))) {
                if (clusterIndices[search_index] == cluster_par) {
                  clusterIndices[search_index] <- as.character(maxlabel + j)
                  j <- j + 1
                }
              }
            }
          },
            error = function(e) {
              j <- 1
              maxlabel <- max(as.numeric(clusterIndices))
              for (search_index in seq(1, length(clusterIndices))) {
                if (clusterIndices[search_index] == cluster_par) {
                  clusterIndices[search_index] <- as.character(maxlabel + j)
                  j <- j + 1
                }
              }
            }
          )

        }

      }
    }

    return(list(clustStats, clusterIndices))
  }

nClusters <- function(labels) {
  sum(table(labels) > 1)
}

percentageInCluster <- function(labels) {
  Nb <- sum(table(labels) == 1)
  (length(labels) - Nb) / length(labels) * 100
}

nMolsPerCluster <- function(labels) {
  length(labels) * percentageInCluster(labels) / (100 * nClusters(labels))
}

clusterRadii <- function(pts, labels) {
  radii <- tapply(1:(dim(pts)[1]), labels, function(v) {
    if (length(v) == 1)
      -1
    else {
      mean(c(sd(pts[v, 1]), sd(pts[v, 2])))
    }
  })
  radii[radii >= 0]
}

clusterStatistics <- function(pts, labels) {
  iscluster <- table(labels) > 1
  if (sum(iscluster) == 0)
    return(-1)
  clusters <- names(which(iscluster))
  sapply(clusters, function(l) {
    ptsl <- pts[labels == l,]
    v <- c(colMeans(ptsl[, 1:2]), mean(c(sd(ptsl[, 1]), sd(ptsl[, 2]))), dim(ptsl)[1])
    dim(v) <- c(4, 1)
    v
  })
}

reldensity <- function(pts, labels, areaclustered, xlim, ylim) {
  rs <- clusterRadii(pts, labels)
  tb <- table(labels)
  nclustered <- sum(tb[tb >= 2])
  nb <- length(labels) - nclustered
  # areaclustered = unlist(cluster_area_density(pts, labels)[2], use.names = F)
  (nclustered / sum(areaclustered)) / (nb / (diff(xlim) * diff(ylim) - sum(areaclustered)))
}
