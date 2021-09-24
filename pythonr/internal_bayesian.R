# Title     : Exporting to hdf5
# Objective : Exporting datasets and metadata to an existing hdf5 file
# Adapted from: Griffié et al.
# Adapted and written by: Saskia Kutz

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
  # taken from Griffié et al.

  N <- dim(pts)[1]
  fsd <- Vectorize(function(sd) {
    wts <- 1 / (sd^2 + sds^2)
    tildeN <- sum(wts)
    mu <- c(sum(wts * pts[, 1]) / tildeN, sum(wts * pts[, 2]) / tildeN)
    totdist <- sum(c(wts * (pts[, 1] - mu[1])^2, wts * (pts[, 2] - mu[2])^
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
  x <- seq(minsd, maxsd, length = grid)[-1]

  values <- fsd(x)
  dx <- x[2] - x[1]
  m <- max(values)
  int <- sum(exp(values - m)) * dx

  log(int) + m #return argument
}

toroid <- function(pts, xlim, ylim, range) {
  # taken from Griffié et al.

  xd <- xlim[2] - xlim[1]
  yd <- ylim[2] - ylim[1]
  R <- pts[pts[, 1] >= (xlim[2] - range), , drop = FALSE]
  Rshift <- t(apply(R, 1, function(v) {
    v - c(xd, 0)
  }))
  L <- pts[pts[, 1] <= range, , drop = FALSE]
  Lshift <- t(apply(L, 1, function(v) {
    v + c(xd, 0)
  }))
  U <- pts[pts[, 2] >= ylim[2] - range, , drop = FALSE]
  Ushift <- t(apply(U, 1, function(v) {
    v - c(0, yd)
  }))
  D <- pts[pts[, 2] <= range, , drop = FALSE]
  Dshift <- t(apply(D, 1, function(v) {
    v + c(0, yd)
  }))

  LU <- pts[(pts[, 1] <= range) &
              (pts[, 2] >= ylim[2] - range), , drop = FALSE]
  LUshift <- t(apply(LU, 1, function(v) {
    v + c(xd, -yd)
  }))
  RU <- pts[(pts[, 1] >= xlim[2] - range) &
              (pts[, 2] >= ylim[2] - range), , drop = FALSE]
  RUshift <- t(apply(RU, 1, function(v) {
    v + c(-xd, -yd)
  }))
  RD <- pts[(pts[, 1] >= xlim[2] - range) &
              (pts[, 2] <= range), , drop = FALSE]
  RDshift <- t(apply(RD, 1, function(v) {
    v + c(-xd, yd)
  }))
  LD <- pts[(pts[, 1] <= range) &
              (pts[, 2] <= range), , drop = FALSE]
  LDshift <- t(apply(LD, 1, function(v) {
    v + c(xd, yd)
  }))
  if (length(Rshift) > 0)
    pts <- rbind(pts, Rshift)
  if (length(Lshift) > 0)
    pts <- rbind(pts, Lshift)
  if (length(Ushift) > 0)
    pts <- rbind(pts, Ushift)
  if (length(Dshift) > 0)
    pts <- rbind(pts, Dshift)
  if (length(LUshift) > 0)
    pts <- rbind(pts, LUshift)
  if (length(RUshift) > 0)
    pts <- rbind(pts, RUshift)
  if (length(RDshift) > 0)
    pts <- rbind(pts, RDshift)
  if (length(LDshift) > 0)
    pts <- rbind(pts, LDshift)
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
  # adapted from Griffié et al.
  # clustering in parallel fashion

  N <- dim(pts)[1]
  if (N == 1) {
    rs <- c()
    ths <- c()
    for (r in rseq) {
      for (th in thseq) {
        rs <- c(rs, r)
        ths <- c(ths, th)
      }
    }
    labels <- rep(1, length(rs))
    dim(labels) <- c(length(rs), 1)
    return(list(
      scores = rep(0, length(rs)),
      scale = rs,
      thresh = ths,
      labels = labels
    ))
  }

  if (!clustermethod == "ToMATo" & !clustermethod == "DBSCAN2") {
    tor <- toroid(pts, xlim, ylim, max(rseq))
    D <- as.matrix(dist(tor))
    D <- D[1:N, 1:N]
  }

  if (.Platform$OS.type == 'windows'){
    cl <- parallel::makeCluster(numCores, type = 'PSOCK')
    doParallel::registerDoParallel(cl)
  }else{
    doParallel::registerDoParallel(cores = numCores)
  }

  x <- foreach::foreach(r = rseq, .export = c('label_correction', 'scorewprec', 'plabel', 'mcgaussprec')) %:%
    foreach::foreach(th = thseq) %dopar% {

    if (!clustermethod == "ToMATo" & !clustermethod == "DBSCAN2") {
      K <- apply(D, 1, function(v) {
        sum(v <= r) - 1
      })
      L <- sqrt((diff(xlim) + 2 * max(rseq)) *
                  (diff(ylim) + 2 * max(rseq)) *
                  K /
                  (pi * (dim(tor)[1] - 1)))
      C <- which(L >= th)
    }

    if (clustermethod == "Ripley' K based") {
      if (length(C) > 0) {
        G <- igraph::graph.adjacency(D[C, C] < 2 * r)
        lab <- igraph::clusters(G, "weak") #graph theory
        labels <- (N + 1):(2 * N)
        labels[C] <- lab$membership #numeric vector giving the cluster id to which each vertex belongs
      }
      else
        labels <- 1:N
    }

    if (clustermethod == "DBSCAN") {
      if (length(C) > 0) {
        G <- igraph::graph.adjacency(D[C, C] < r)
        lab <- igraph::clusters(G, "weak")
        labels <- (N + 1):(2 * N)
        labels[C] <- lab$membership
        ##hoovering up boundary points by (arbitrarily) assigning to the first clustered
        for (i in (1:N)[-C]) {
          closeto <- which(D[C, i] < r)
          if (length(closeto) > 0)
            labels[i] <- labels[C[closeto[1]]]
        }
      }
      else
        labels <- 1:N
    }

    if (clustermethod == "ToMATo") {
      labels <- RSMLM::clusterTomato(pts, r, th)
      labels <- label_correction(labels)
    }

    if (clustermethod == "DBSCAN2") {
      labels <- RSMLM::clusterDBSCAN(pts, r, th)
      labels <- label_correction(labels)
    }

    s <- 0
    if (score) {
      s <- mean(labels)
      s <- scorewprec(
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
      scores <- s

    if (report) {
      cat("Scale:", r, "Thr:", th, "Score: ", s, "\n")
    }
    if (rlabel) {
      retlabels <- labels
    }

    list(
      scores = s,
      scale = r,
      thresh = th,
      labels = retlabels
    )
  }
  if (.Platform$OS.type == 'windows'){
    parallel::stopCluster(cl)
  }
  return(x)
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
  # adapted from Griffié et al.
  # clsutering in sequential fashion

  N <- dim(pts)[1]
  if (N == 1) {
    rs <- c()
    ths <- c()
    for (r in rseq) {
      for (th in thseq) {
        rs <- c(rs, r)
        ths <- c(ths, th)
      }
    }
    labels <- rep(1, length(rs))
    dim(labels) <- c(length(rs), 1)
    return(list(
      scores = rep(0, length(rs)),
      scale = rs,
      thresh = ths,
      labels = labels
    ))
  }
  if (!clustermethod == "ToMATo") {
    tor <- toroid(pts, xlim, ylim, max(rseq))
    D <- as.matrix(dist(tor))
    D <- D[1:N, 1:N]
  }
  scores <- c()
  retlabels <- c()
  rs <- c()
  ths <- c()
  for (r in rseq) {
    if (!clustermethod == "ToMATo" & !clustermethod == "DBSCAN2") {
      K <- apply(D, 1, function(v) {
        sum(v <= r) - 1
      })
      L <- sqrt((diff(xlim) + 2 * max(rseq)) *
                  (diff(ylim) + 2 * max(rseq)) *
                  K /
                  (pi * (dim(tor)[1] - 1)))
    }
    for (th in thseq) {

      if (!clustermethod == "ToMATo" & !clustermethod == "DBSCAN2")
        C <- which(L >= th)
      if (clustermethod == "Ripley' K based") {
        if (length(C) > 0) {
          G <- graph.adjacency(D[C, C] < 2 * r)
          lab <- clusters(G, "weak") #graph theory
          labels <- (N + 1):(2 * N)
          labels[C] <- lab$membership #numeric vector giving the cluster id to which each vertex belongs
        }
        else
          labels <- 1:N
      }
      if (clustermethod == "DBSCAN") {
        if (length(C) > 0) {
          G <- graph.adjacency(D[C, C] < r)
          lab <- clusters(G, "weak")
          labels <- (N + 1):(2 * N)
          labels[C] <- lab$membership
          ##hoovering up boundary points by (arbitrarily) assigning to the first clustered
          for (i in (1:N)[-C]) {
            closeto <- which(D[C, i] < r)
            if (length(closeto) > 0)
              labels[i] <- labels[C[closeto[1]]]
          }
        }
        else
          labels <- 1:N
      }
      if (clustermethod == "ToMATo") {
        labels <- clusterTomato(pts, r, th)
        labels <- label_correction(labels)
      }
      if (clustermethod == "DBSCAN2") {
        labels <- clusterDBSCAN(pts, r, th)
        labels <- label_correction(labels)
      }
      s <- 0
      if (score) {
        s <- scorewprec(
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
        scores <- c(scores, s)
      }
      rs <- c(rs, r)
      ths <- c(ths, th)

      if (report) {
        cat("Scale:", r, "Thr:", th, "Score: ", s, "\n")
      }
      if (rlabel) {
        retlabels <- rbind(retlabels, labels)
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

writeRes_seq <- function(res, datah5file, bestonly = FALSE) {
  # adaped from Griffié et al.
  # exporting of score results to hdf5

  scale <- unique(res[["scale"]])
  scale <- scale[order(as.numeric(scale))]
  thresh <- unique(res[["thresh"]])
  thresh <- thresh[order(as.numeric(thresh))]

  tmp_matrix <- matrix(nrow = length(thresh), ncol = length(scale))
  rownames(tmp_matrix) <- thresh
  colnames(tmp_matrix) <- scale
  for (th in seq(length(thresh))) {
    for (i in seq(length(res[['scores']]))) {
      tmp_matrix[toString(res[['thresh']][i]), toString(res[['scale']][i])] <- res[['scores']][i]
    }
  }
  write_df_hdf5(datah5file, tmp_matrix, 'r_vs_thresh')
  write_metadata_df(datah5file, colnames(tmp_matrix), 'r_vs_thresh', 'scales')
  write_metadata_df(datah5file, rownames(tmp_matrix), 'r_vs_thresh', 'thresholds')

  create_hdf5group(datah5file, 'labels')

  if (bestonly)
    is <- which.max(res[["scores"]])
  else
    is <- (1:dim(res[["labels"]])[1])
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
  # exporting of scores to hdf5 from parallel computation

  tmp_matrix <- matrix(nrow = length(thseq), ncol = length(rseq))
  rownames(tmp_matrix) <- thseq
  colnames(tmp_matrix) <- rseq

  for (para1 in seq(1, length(rseq))) {
    for (para2 in seq(1, length(thseq))) {
      tmp_matrix[toString(res[[para1]][[para2]][["thresh"]]), toString(res[[para1]][[para2]][["scale"]])] <-
        res[[para1]][[para2]][["scores"]]
    }
  }
  write_df_hdf5(datah5file, tmp_matrix, 'r_vs_thresh')
  write_metadata_df(datah5file, rseq, 'r_vs_thresh', 'scales')
  write_metadata_df(datah5file, thseq, 'r_vs_thresh', 'thresholds')
}

writeRes_labels <- function(res, rseq, thseq, datah5file) {
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
    }
  }
}

plabel <- function(labels, alpha, pb) {
  # taken from Griffié et al.

  cnt <- tapply(1:length(labels), labels, length)
  cl <- cnt[cnt != 1]
  B <- length(labels) - sum(cl)
  Bcont <- B * log(pb) + (1 - B) * log(1 - pb)
  ## Green 2001 p.357, Scand J Statist 28
  partcont <- 0
  if (length(cl) > 0)
    partcont <- length(cl) * log(alpha) +
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
  # taken from Griffié et al.
  # scoring

  s <- sum(tapply(1:(dim(pts)[1]), labels, function(v) {
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
  prlab <- 0
  if (useplabel) {
    if (is.null(alpha)) {
      cnt <- tapply(1:length(labels), labels, length)
      n <- sum(cnt[cnt != 1])
      alpha <- 20
    }
    prlab <- plabel(labels, alpha, pb)
  }
  s + prlab
}

label_correction <- function(labels) {
  # label correction for labels calulated with ToMATo

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
