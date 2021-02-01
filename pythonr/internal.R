if (!require(pacman, quietly = TRUE))
  install.packages("pacman")
# if (!require(devtools))
#   install.packages("devtools")
# if (!require(RSMLM))
#   pacman::p_load("devtools")
#   install_github("lucabaronti/RSMLM")
pacman::p_load(
  "dplyr",
  "pryr",
  "ggpubr",
  "splancs",
  "igraph",
  "RSMLM",
  "tictoc",
  "geometry",
  "doParallel",
  "beepr",
  "data.table",
  "plyr",
  "ggforce",
  "tidyverse",
  "rhdf5"
)
pacman::p_load_gh("lucabaronti/RSMLM")


mcgaussprec <- function(pts,
                        sds,
                        xlim = c(0, 1),
                        ylim = c(0, 1),
                        psd = function(sd) {
                          0
                        },
                        minsd = 0.1,
                        maxsd = 100,
                        grid = 100) {
  N = dim(pts)[1]
  fsd <- Vectorize(function(sd) {
    wts = 1 / (sd^2 + sds^2)
    tildeN = sum(wts)
    mu = c(sum(wts * pts[, 1]) / tildeN, sum(wts * pts[, 2]) / tildeN)
    totdist = sum(c(wts * (pts[, 1] - mu[1])^2, wts * (pts[, 2] - mu[2])^
      2))

    ##x-axis
    log(pnorm(sqrt(tildeN) * (xlim[2] - mu[1])) - pnorm(sqrt(tildeN) * (xlim[1] - mu[1]))) +
      ##y-axis
      log(pnorm(sqrt(tildeN) * (ylim[2] - mu[2])) - pnorm(sqrt(tildeN) * (ylim[1] - mu[2]))) +
      ##marginalised (with factor 2pi taken from standardisation above)
      -(N - 1) * log(2 * pi) +
      sum(log(wts)) - totdist / 2 +
      ##size of area
      -log(diff(xlim) * diff(ylim)) +
      ##cst -- left in standardisation above
      -log(tildeN) +
      ##prior on sd
      psd(sd)
  })
  ##discrete prior:
  x = seq(minsd, maxsd, length = grid)[-1]

  values = fsd(x)
  dx = x[2] - x[1]
  m = max(values)
  int = sum(exp(values - m)) * dx

  log(int) + m #return argument
}


mkcols <- function(labels) {
  t = table(labels)
  cnames = names(t[t > 1])
  colors = sample(rainbow(length(cnames)))
  s = sapply(labels, function(l) {
    i = which(names(t) == l)

    if (t[i] == 1) {
      "grey"
    }
    else {
      colors[which(cnames == l)]
    }
  })
  s
}

toroid <- function(pts, xlim, ylim, range) {
  xd = xlim[2] - xlim[1]
  yd = ylim[2] - ylim[1]
  R = pts[pts[, 1] >= (xlim[2] - range), , drop = FALSE]
  Rshift = t(apply(R, 1, function(v) {
    v - c(xd, 0)
  }))
  L = pts[pts[, 1] <= range, , drop = FALSE]
  Lshift = t(apply(L, 1, function(v) {
    v + c(xd, 0)
  }))
  U = pts[pts[, 2] >= ylim[2] - range, , drop = FALSE]
  Ushift = t(apply(U, 1, function(v) {
    v - c(0, yd)
  }))
  D = pts[pts[, 2] <= range, , drop = FALSE]
  Dshift = t(apply(D, 1, function(v) {
    v + c(0, yd)
  }))

  LU = pts[(pts[, 1] <= range) &
             (pts[, 2] >= ylim[2] - range), , drop = FALSE]
  LUshift = t(apply(LU, 1, function(v) {
    v + c(xd, -yd)
  }))
  RU = pts[(pts[, 1] >= xlim[2] - range) &
             (pts[, 2] >= ylim[2] - range), , drop = FALSE]
  RUshift = t(apply(RU, 1, function(v) {
    v + c(-xd, -yd)
  }))
  RD = pts[(pts[, 1] >= xlim[2] - range) &
             (pts[, 2] <= range), , drop = FALSE]
  RDshift = t(apply(RD, 1, function(v) {
    v + c(-xd, yd)
  }))
  LD = pts[(pts[, 1] <= range) &
             (pts[, 2] <= range), , drop = FALSE]
  LDshift = t(apply(LD, 1, function(v) {
    v + c(xd, yd)
  }))
  if (length(Rshift) > 0)
    pts = rbind(pts, Rshift)
  if (length(Lshift) > 0)
    pts = rbind(pts, Lshift)
  if (length(Ushift) > 0)
    pts = rbind(pts, Ushift)
  if (length(Dshift) > 0)
    pts = rbind(pts, Dshift)
  if (length(LUshift) > 0)
    pts = rbind(pts, LUshift)
  if (length(RUshift) > 0)
    pts = rbind(pts, RUshift)
  if (length(RDshift) > 0)
    pts = rbind(pts, RDshift)
  if (length(LDshift) > 0)
    pts = rbind(pts, LDshift)
  pts
}

Kclust_parallel <- function(pts,
                            sds = 0,
                            xlim,
                            ylim,
                            psd = NULL,
                            minsd = NULL,
                            maxsd = NULL,
                            useplabel = TRUE,
                            alpha = NULL,
                            pb = .5,
                            rseq = seq(10, 200, by = 5),
                            thseq = seq(5, 500, by = 5),
                            score = T,
                            rlabel = T,
                            report = F,
                            clustermethod = "Ripley' K based",
                            numCores = 1) {
  N = dim(pts)[1]
  if (N == 1) {
    rs = c()
    ths = c()
    for (r in rseq) {
      for (th in thseq) {
        rs = c(rs, r)
        ths = c(ths, th)
      }
    }
    labels = rep(1, length(rs))
    dim(labels) = c(length(rs), 1)
    return(list(
      scores = rep(0, length(rs)),
      scale = rs,
      thresh = ths,
      labels = labels
    ))
  }

  if (!clustermethod == "ToMATo" & !clustermethod == "DBSCAN2") {
    tor = toroid(pts, xlim, ylim, max(rseq))
    D = as.matrix(dist(tor))
    D = D[1:N, 1:N]
  }
  registerDoParallel(cores = numCores)
  foreach(r = rseq) %:%
    foreach(th = thseq) %dopar% {

    if (!clustermethod == "ToMATo" & !clustermethod == "DBSCAN2") {
      K = apply(D, 1, function(v) {
        sum(v <= r) - 1
      })
      L = sqrt((diff(xlim) + 2 * max(rseq)) *
                 (diff(ylim) + 2 * max(rseq)) *
                 K /
                 (pi * (dim(tor)[1] - 1)))
      C = which(L >= th)
    }

    if (clustermethod == "Ripley' K based") {
      if (length(C) > 0) {
        G = graph.adjacency(D[C, C] < 2 * r)
        lab = clusters(G, "weak") #graph theory
        labels = (N + 1):(2 * N)
        labels[C] = lab$membership #numeric vector giving the cluster id to which each vertex belongs
      }
      else
        labels = 1:N
    }

    if (clustermethod == "DBSCAN") {
      if (length(C) > 0) {
        G = graph.adjacency(D[C, C] < r)
        lab = clusters(G, "weak")
        labels = (N + 1):(2 * N)
        labels[C] = lab$membership
        ##hoovering up boundary points by (arbitrarily) assigning to the first clustered
        for (i in (1:N)[-C]) {
          closeto = which(D[C, i] < r)
          if (length(closeto) > 0)
            labels[i] = labels[C[closeto[1]]]
        }
      }
      else
        labels = 1:N
    }

    if (clustermethod == "ToMATo") {
      labels = clusterTomato(pts, r, th)
      labels = label_correction(labels)
    }

    if (clustermethod == "DBSCAN2") {
      labels = clusterDBSCAN(pts, r, th)
      labels = label_correction(labels)
    }

    s = 0
    if (score) {
      s = mean(labels)
      s = scorewprec(
        labels = labels,
        pts = pts,
        sds = sds,
        xlim = xlim,
        ylim = ylim,
        psd = psd,
        minsd = minsd,
        maxsd = maxsd,
        useplabel = useplabel,
        alpha = alpha,
        pb = pb
      )
    }
    else
      scores = s

    if (report) {
      cat("Scale:", r, "Thr:", th, "Score: ", s, "\n")
    }
    if (rlabel) {
      retlabels = labels
    }
    # data.frame(scores=scores, scale=rs, thresh=ths, labels=retlabels) #return argument
    list(
      scores = s,
      scale = r,
      thresh = th,
      labels = retlabels
    )
  }
}


Kclust_sequential <- function(pts,
                              sds = 0,
                              xlim,
                              ylim,
                              psd = NULL,
                              minsd = NULL,
                              maxsd = NULL,
                              useplabel = TRUE,
                              alpha = NULL,
                              pb = .5,
                              rseq = seq(10, 200, by = 5),
                              thseq = seq(5, 500, by = 5),
                              score = FALSE,
                              rlabel = FALSE,
                              report = FALSE,
                              clustermethod = "Ripley' K based") {
  N = dim(pts)[1]
  if (N == 1) {
    rs = c()
    ths = c()
    for (r in rseq) {
      for (th in thseq) {
        rs = c(rs, r)
        ths = c(ths, th)
      }
    }
    labels = rep(1, length(rs))
    dim(labels) = c(length(rs), 1)
    return(list(
      scores = rep(0, length(rs)),
      scale = rs,
      thresh = ths,
      labels = labels
    ))
  }
  if (!clustermethod == "ToMATo") {
    tor = toroid(pts, xlim, ylim, max(rseq))
    D = as.matrix(dist(tor))
    D = D[1:N, 1:N]
  }
  scores = c()
  retlabels = c()
  rs = c()
  ths = c()
  for (r in rseq) {
    if (!clustermethod == "ToMATo" & !clustermethod == "DBSCAN2") {
      K = apply(D, 1, function(v) {
        sum(v <= r) - 1
      })
      L = sqrt((diff(xlim) + 2 * max(rseq)) *
                 (diff(ylim) + 2 * max(rseq)) *
                 K /
                 (pi * (dim(tor)[1] - 1)))
    }
    for (th in thseq) {

      # if ( th%%RAMmodulo == 0){
      #   if ( RAMmax < mem_used()){
      #     abort("too much RAM")
      #   }
      # }

      if (!clustermethod == "ToMATo" & !clustermethod == "DBSCAN2")
        C = which(L >= th)
      if (clustermethod == "Ripley' K based") {
        if (length(C) > 0) {
          G = graph.adjacency(D[C, C] < 2 * r)
          lab = clusters(G, "weak") #graph theory
          labels = (N + 1):(2 * N)
          labels[C] = lab$membership #numeric vector giving the cluster id to which each vertex belongs
        }
        else
          labels = 1:N
      }
      if (clustermethod == "DBSCAN") {
        if (length(C) > 0) {
          G = graph.adjacency(D[C, C] < r)
          lab = clusters(G, "weak")
          labels = (N + 1):(2 * N)
          labels[C] = lab$membership
          ##hoovering up boundary points by (arbitrarily) assigning to the first clustered
          for (i in (1:N)[-C]) {
            closeto = which(D[C, i] < r)
            if (length(closeto) > 0)
              labels[i] = labels[C[closeto[1]]]
          }
        }
        else
          labels = 1:N
      }
      if (clustermethod == "ToMATo") {
        labels <- clusterTomato(pts, r, th)
        labels <- label_correction(labels)
      }
      if (clustermethod == "DBSCAN2") {
        labels <- clusterDBSCAN(pts, r, th)
        labels <- label_correction(labels)
      }
      s = 0
      if (score) {
        s = scorewprec(
          labels = labels,
          pts = pts,
          sds = sds,
          xlim = xlim,
          ylim = ylim,
          psd = psd,
          minsd = minsd,
          maxsd = maxsd,
          useplabel = useplabel,
          alpha = alpha,
          pb = pb
        )
        scores = c(scores, s)
      }
      rs = c(rs, r)
      ths = c(ths, th)

      if (report) {
        cat("Scale:", r, "Thr:", th, "Score: ", s, "\n")
      }
      if (rlabel) {
        retlabels = rbind(retlabels, labels)
      }
    }
  }
  list(
    scores = scores,
    scale = rs,
    thresh = ths,
    labels = retlabels
  ) #return argument
}


writeRes <- function(res, rfile, labdir, bestonly = FALSE) {
  scale = unique(res[["scale"]])
  scale = scale[order(as.numeric(scale))]
  thresh = unique(res[["thresh"]])
  thresh = thresh[order(as.numeric(thresh))]
  cat("0", scale, sep = "\t", file = rfile)
  cat("\n", file = rfile, append = TRUE)
  for (line in thresh) {
    scales = res[["scale"]][res[["thresh"]] == line]
    o = order(scales)
    scales = scales[o]
    scores = res[["scores"]][res[["thresh"]] == line]
    scores = scores[o]
    cat(line,
        "\t",
        sep = "",
        file = rfile,
        append = TRUE)
    cat(scores,
        sep = "\t",
        append = TRUE,
        file = rfile)
    cat("\n", file = rfile, append = TRUE)
  }
  dir.create(labdir, showWarnings = F)
  if (bestonly)
    is = which.max(res[["scores"]])
  else
    is = (1:dim(res[["labels"]])[1])
  for (i in is) {
    fwrite(res[["labels"]][i,], file.path(
      paste0(
        labdir,
        "/clusterscale",
        res[["scale"]][i],
        "_thresh",
        res[["thresh"]][i],
        "labels.txt"
      )
    ))
  }
}

writeRes_seq <- function(res, datah5file, bestonly = FALSE) { # , rfile, labdir,
  scale = unique(res[["scale"]])
  scale = scale[order(as.numeric(scale))]
  thresh = unique(res[["thresh"]])
  thresh = thresh[order(as.numeric(thresh))]

  tmp_matrix <- matrix(nrow = length(thresh), ncol = length(scale))
  rownames(tmp_matrix) <- thresh
  colnames(tmp_matrix) <- scale
  for (th in seq(length(thresh))) {
    for (i in seq(length(res[['scores']]))) {
      tmp_matrix[toString(res[['thresh']][i]), toString(res[['scale']][i])] <- res[['scores']][i]
    }
  }
  tryCatch({
    h5write(tmp_matrix, datah5file, 'r_vs_thresh') },
    error = function(e) {
      h5delete(datah5file, 'r_vs_thresh')
      h5write(tmp_matrix, datah5file, 'r_vs_thresh')
    }
  )
  did <- H5Dopen(datah5file, 'r_vs_thresh')
  h5writeAttribute(did, attr = colnames(tmp_matrix), name = 'colnames')
  h5writeAttribute(did, attr = rownames(tmp_matrix), name = 'rownames')
  H5Dclose(did)

  tryCatch({
    handle = h5createGroup(datah5file, 'labels') },
    error = function(e) {
      h5delete(datah5file, 'labels')
      h5createGroup(datah5file, 'labels') },
    warning = function(w) { w }
  )
  if (handle == FALSE) {
    h5delete(datah5file, 'labels')
    h5createGroup(datah5file, 'labels')
  }

  if (bestonly)
    is = which.max(res[["scores"]])
  else
    is = (1:dim(res[["labels"]])[1])
  for (i in is) {
    c <- res[['labels']][i,]
    h5write(c,
            datah5file,
            paste0('labels/clusterscale',
                   res[['scale']][i],
                   '_thresh',
                   res[["thresh"]][i]))
  }
}

writeRes_r_vs_th <- function(res, rseq, thseq, datah5file) {
  tmp_matrix <- matrix(nrow = length(thseq), ncol = length(rseq))
  rownames(tmp_matrix) <- thseq
  colnames(tmp_matrix) <- rseq

  for (para1 in seq(1, length(rseq))) {
    for (para2 in seq(1, length(thseq))) {
      tmp_matrix[toString(res[[para1]][[para2]][["thresh"]]), toString(res[[para1]][[para2]][["scale"]])] <-
        res[[para1]][[para2]][["scores"]]
    }
  }
  tryCatch({
    h5write(tmp_matrix, datah5file, 'r_vs_thresh') },
    error = function(e) {
      h5delete(datah5file, 'r_vs_thresh')
      h5write(tmp_matrix, datah5file, 'r_vs_thresh')
    }
  )
  did <- H5Dopen(datah5file, 'r_vs_thresh')
  h5writeAttribute(did, attr = rseq, 'scales')
  h5writeAttribute(did, attr = thseq, 'thresholds')
  H5Dclose(did)
  # write.table(
  #   tmp_matrix,
  #   file = rfile,
  #   sep = "\t",
  #   row.names = T,
  #   col.names = T
  # )
}

writeRes_labels <- function(res, rseq, thseq, datah5file) {
  #dir.create(labdir, showWarnings = F)
  tryCatch({
    h5createGroup(datah5file, 'labels') },
    error = function(e) {
      h5delete(datah5file, 'labels')
      h5createGroup(datah5file, 'labels') },
    warning = function(w) { w }
  )
  for (para1 in seq(1, length(rseq))) {
    for (para2 in seq(1, length(thseq))) {
      c <- res[[para1]][[para2]][['labels']]
      h5write(c,
              datah5file,
              paste0('labels/clusterscale',
                     res[[para1]][[para2]][["scale"]],
                     '_thresh',
                     res[[para1]][[para2]][["thresh"]]))
      # fwrite(as.list(res[[para1]][[para2]][["labels"]]), file.path(
      #   paste0(
      #     labdir,
      #     "/clusterscale",
      #     res[[para1]][[para2]][["scale"]],
      #     "_thresh",
      #     res[[para1]][[para2]][["thresh"]],
      #     "labels.txt",
      #     sep = ""
      #   )
      # ))
    }
  }
}

nClusters <- function(labels) {
  sum(table(labels) > 1)
}

percentageInCluster <- function(labels) {
  Nb = sum(table(labels) == 1)
  (length(labels) - Nb) / length(labels) * 100
}

molsPerCluster <- function(labels) {
  ta = table(labels)
  ta[ta > 1]
}

nMolsPerCluster <- function(labels) {
  length(labels) * percentageInCluster(labels) / (100 * nClusters(labels))
}

histnMols <- function(labels) {
  ta = table(labels)[table(labels) > 1]
  h = hist(ta, plot = FALSE)
  plot(h,
       xlab = "Number of molecules",
       ylab = "Number of clusters",
       main = "")
}

clusterRadii <- function(pts, labels) {
  radii = tapply(1:(dim(pts)[1]), labels, function(v) {
    if (length(v) == 1)
      -1
    else {
      mean(c(sd(pts[v, 1]), sd(pts[v, 2])))
    }
  })
  radii[radii >= 0]
}

clusterStatistics <- function(pts, labels) {
  iscluster = table(labels) > 1
  if (sum(iscluster) == 0)
    return(-1)
  clusters = names(which(iscluster))
  sapply(clusters, function(l) {
    ptsl = pts[labels == l,]
    v = c(colMeans(ptsl[, 1:2]), mean(c(sd(ptsl[, 1]), sd(ptsl[, 2]))), dim(ptsl)[1])
    dim(v) = c(4, 1)
    v
  })
}

convexHullAreas <- function(pts, labels) {
  areas = tapply(1:(dim(pts)[1]), labels, function(v) {
    if (length(v) == 1)
      -1
    else {
      i <- chull(pts[v, 1], pts[v, 2])
      areapl(as.matrix(pts[v[i],]))
    }
  })
  areas[areas >= 0]
}


reldensity <- function(pts, labels, areaclustered, xlim, ylim) {
  rs = clusterRadii(pts, labels)
  tb = table(labels)
  nclustered = sum(tb[tb >= 2])
  nb = length(labels) - nclustered
  # areaclustered = unlist(cluster_area_density(pts, labels)[2], use.names = F)
  (nclustered / sum(areaclustered)) / (nb / (diff(xlim) * diff(ylim) - sum(areaclustered)))
}

plabel <- function(labels, alpha, pb) {
  cnt <- tapply(1:length(labels), labels, length)
  cl = cnt[cnt != 1]
  B = length(labels) - sum(cl)
  Bcont = B * log(pb) + (1 - B) * log(1 - pb)
  ## Green 2001 p.357, Scand J Statist 28
  partcont = 0
  if (length(cl) > 0)
    partcont = length(cl) * log(alpha) +
      lgamma(alpha) +
      sum(lgamma(cl)) -
      lgamma(alpha + sum(cl))
  Bcont + partcont
}

scorewprec <- function(labels,
                       pts,
                       sds,
                       xlim,
                       ylim,
                       psd,
                       minsd,
                       maxsd,
                       useplabel = TRUE,
                       alpha = NULL,
                       pb = .5) {
  s = sum(tapply(1:(dim(pts)[1]), labels, function(v) {
    if (length(v) > 1)
      mcgaussprec(
        pts[v,],
        sds[v],
        xlim,
        ylim,
        psd = psd,
        minsd = minsd,
        maxsd = maxsd
      )
    else
      -log(diff(xlim) * diff(ylim))
  }))
  prlab = 0
  if (useplabel) {
    if (is.null(alpha)) {
      cnt <- tapply(1:length(labels), labels, length)
      n = sum(cnt[cnt != 1])
      alpha = 20
    }
    prlab = plabel(labels, alpha, pb)
  }
  s + prlab
}

label_correction <- function(labels) {
  j <- 1
  maxlabel <- max(labels)
  for (bgl in seq(1, length(labels))) {
    if (labels[bgl] == 0) {
      labels[bgl] <- maxlabel + j
      j <- j + 1
    }
  }
  labels
}

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

import_data <- function(foldername) {
  dataset_locs = list.files(file.path(foldername), pattern = "*.txt")
  dataset_locs = dataset_locs[dataset_locs != "r_vs_thresh.txt" &
                                dataset_locs != "../config.txt" &
                                dataset_locs != "summary.txt" &
                                dataset_locs != "cluster-statistics.txt" &
                                dataset_locs != "summary_ground_truth.txt"]
  data_locs = read.csv(file.path(paste0(foldername, "/", dataset_locs, sep = "")))
  data_locs
}
