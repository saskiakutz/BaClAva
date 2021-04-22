# histograms --------------------------------------------------------------

hist_plot <- function(res, nexpname, plotcreation) {

  length_res <- length(names(res[[1]]))
  if (length_res == 9)
    length_res <- 8
  for (j in 1:length_res) {
    datavec <- c()
    for (i in 1:length(res)) {
      datavec <- c(datavec, unlist(res[[i]][j], use.names = F))
    }
    if (length(datavec) != 0 & !all(is.na(datavec))) {
      k <-
        case_when( #need to correct relative density
          j == 1 ~ c("Cluster radius", "Number of clusters"),
          j == 2 ~ c("Number of molecules", "Number of clusters"),
          j == 3 ~ c("Number of clusters", "Number of regions"),
          j == 4 ~ c("Percentage clustered", "Number of regions"),
          j == 5 ~ c("Total Mols per ROI", "Number of regions"),
          j == 6 ~ c("Total Mols per ROI", "Number of regions"),
          j == 7 ~ c("Cluster area", "Number of clusters"),
          j == 8 ~ c("Cluster density", "Number of clusters")
        )

      #plot
      if (plotcreation) {
        tryCatch({
          bw <- 2 * IQR(datavec) / length(datavec)^(1 / 3)
          ggplot() +
            aes(datavec) +
            geom_histogram(binwidth = bw) +
            labs(x = k[1], y = k[2]) +
            theme_bw() +
            ggsave(file.path(
              paste0(nexpname, "/", "histogram_", names(res[[1]][j]), ".pdf", sep = "")
            ),
                   width = 5,
                   height = 5) +
            ggsave(file.path(
              paste0(nexpname, "/", "histogram_", names(res[[1]][j]), ".eps", sep = "")
            ),
                   width = 5,
                   height = 5) +
            ggsave(file.path(
              paste0(nexpname, "/", "histogram_", names(res[[1]][j]), ".png", sep = "")
            ),
                   width = 5,
                   height = 5)
        },
          warning = function(w) {
            bw <- 1
            ggplot() +
              aes(datavec) +
              geom_histogram(binwidth = bw) +
              labs(x = k[1], y = k[2]) +
              theme_bw() +
              ggsave(file.path(
                paste0(nexpname, "/", "histogram_", names(res[[1]][j]), ".pdf", sep = "")
              ),
                     width = 5,
                     height = 5) +
              ggsave(file.path(
                paste0(nexpname, "/", "histogram_", names(res[[1]][j]), ".eps", sep = "")
              ),
                     width = 5,
                     height = 5) +
              ggsave(file.path(
                paste0(nexpname, "/", "histogram_", names(res[[1]][j]), ".png", sep = "")
              ),
                     width = 5,
                     height = 5)
          })

        if (length(datavec) > 1) {
          ggplot() +
            aes(datavec) +
            geom_density() +
            labs(x = k[1]) +
            theme_bw() +
            #geom_vline(xintercept = density(datavec)$x[which.max(density(datavec)$y)]) +
            ggsave(file.path(
              paste0(
                nexpname,
                "/",
                "densityplot_",
                names(res[[1]][j]),
                ".pdf",
                sep = ""
              )
            ),
                   width = 5,
                   height = 5) +
            ggsave(file.path(
              paste0(
                nexpname,
                "/",
                "densityplot_",
                names(res[[1]][j]),
                ".eps",
                sep = ""
              )
            ),

                   width = 5,
                   height = 5) +
            ggsave(file.path(paste0(
              nexpname, "/", "densityplot_", names(res[[1]][j]), ".png", sep = ""
            )),
                   width = 5,
                   height = 5)
        }
      }


      f <- file.path(paste0(nexpname, "/", names(res[[1]][j]), ".txt", sep = ""))
      cat(datavec, file = f, sep = ", ")
      cat("\n", file = f, append = TRUE)
    }

  }
}

hist_plot_fix_limits <-
  function(res,
           nexpname,
           xminimum,
           xmaximum,
           yminimum,
           ymaximum) {
    for (j in 1:length(names(res[[1]]))) {
      for (i in 1:length(res)) {
        datavec <- c()
        datavec <- c(datavec, unlist(res[[i]][j], use.names = F))

        k <-
          case_when(
            j == 1 ~ c("Cluster radius", "Number of clusters"),
            j == 2 ~ c("Number of molecules", "Number of clusters"),
            j == 3 ~ c("Number of clusters", "Number of regions"),
            j == 4 ~ c("Percentage clustered", "Number of regions"),
            j == 5 ~ c("Total Mols per ROI", "Number of regions"),
            j == 6 ~ c("Total Mols per ROI", "Number of regions")
          )

        #plot
        tryCatch({
          bw <- 2 * IQR(datavec) / length(datavec)^(1 / 3)
          ggplot() +
            aes(datavec) +
            geom_histogram(binwidth = bw) +
            labs(x = k[1], y = k[2]) +
            xlim(xminimum, xmaximum) +
            ylim(yminimum, ymaximum) +
            theme_bw() +
            ggsave(file.path(
              paste0(nexpname, "/", names(res[[1]][j]), "_fixlimits", ".pdf", sep = "")
            ),
                   width = 5,
                   height = 5) +
            ggsave(file.path(
              paste0(nexpname, "/", names(res[[1]][j]), "_fixlimits", ".eps", sep = "")
            ),
                   width = 5,
                   height = 5) +
            ggsave(file.path(
              paste0(nexpname, "/", names(res[[1]][j]), "_fixlimits", ".png", sep = "")
            ),
                   width = 5,
                   height = 5)
        },
          warning = function(w) {
            bw <- 2
            ggplot() +
              aes(datavec) +
              geom_histogram(binwidth = bw) +
              labs(x = k[1], y = k[2]) +
              xlim(xminimum, xmaximum) +
              ylim(yminimum, ymaximum) +
              theme_bw(base_size = 24) +
              ggsave(file.path(
                paste0(nexpname, "/", names(res[[1]][j]), "_fixlimits", ".pdf", sep = "")
              ),
                     width = 5,
                     height = 5) +
              ggsave(file.path(
                paste0(nexpname, "/", names(res[[1]][j]), "_fixlimits", ".eps", sep = "")
              ),
                     width = 5,
                     height = 5) +
              ggsave(file.path(
                paste0(nexpname, "/", names(res[[1]][j]), "_fixlimits", ".png", sep = "")
              ),
                     width = 5,
                     height = 5)
          })
      }
    }
  }

cluster_plot <-
  function(pts,
           colourlabels,
           title,
           pointsize = 0.03) {
    dataset <- as_tibble(pts)
    data <- dataset %>%
      mutate(radius_SD = pointsize) %>%
      mutate(labels = colourlabels) %>%
      mutate(colour = mkcols(labels))

    clusterplot <- ggplot() +
      geom_circle(aes(x0 = x, y0 = y, r = radius_SD, fill = colour, color = colour), n = 10, data = data, show.legend = FALSE, linetype = 0.5) +
      coord_fixed() +
      scale_colour_identity() +
      scale_fill_identity() +
      labs(x = "x [µm]", y = "y [µm]") +
      ggtitle(title) +
      theme_bw() +
      theme(
        axis.text = element_text(size = 8),
        plot.title = element_text(size = 8),
        axis.title = element_text(size = 8),
        panel.border = element_rect(size = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "white") #
      )

    clusterplot

  }

plots_arrange <- function(plot1, plot2, n_row, expname, gg_plot_name) {

  arragedplot <- ggarrange(plot1, plot2, nrow = n_row)
  plot_save(arragedplot, expname, gg_plot_name, plot_height = 5, plot_width = 10)

}

cluster_superplot <- function(results, dirnames, expname, gg_plot_name) {
  num_sets <- length(results)
  n_rows <- ceiling(sqrt(length(dirnames)))
  plotlist <- lapply(results, function(set) {
    set[[9]]
  })
  super_plot <- do.call("ggarrange", c(plotlist, ncol = n_rows))
  plot_save(super_plot, expname, gg_plot_name, plot_height = 5, plot_width = 10)
}

plot_save <- function(gg_plot, expname, gg_plot_name, plot_height = 45, plot_width = 45, unit = "mm") {
  gg_plot +
    ggsave(file.path(paste0(
      expname, "/", gg_plot_name, ".pdf", sep = ""
    )), width = plot_width, height = plot_height, units = unit) +
    ggsave(file.path(paste0(
      expname, "/", gg_plot_name, ".eps", sep = ""
    )), width = plot_width, height = plot_height, units = unit) +
    ggsave(file.path(paste0(
      expname, "/", gg_plot_name, ".png", sep = ""
    )), width = plot_width, height = plot_height, units = unit)
}

ground_truth_plot <- function(pts, colourlabels, title) {
  clusterplot <- ggplot(pts, aes(x, y)) +
    geom_point(color = "grey") +
    labs(x = "", y = "") +
    ggtitle(title) +
    theme(
      axis.text = element_text(size = 13),
      panel.background = element_rect(fill = "white", colour = "black")
    )
  clusterplot
}

mkcols <- function(labels) {
  t <- table(labels)
  cnames <- names(t[t > 1])
  colors <- sample(rainbow(length(cnames)))
  s <- sapply(labels, function(l) {
    i <- which(names(t) == l)

    if (t[i] == 1) {
      "grey"
    }
    else {
      colors[which(cnames == l)]
    }
  })
  s
}

# summarytable plots
scatterplot <- function(datatable, col1, col2, col3) {
  scatter_plot <- ggplot(datatable, aes_string(x = col1, y = col2, color = col3)) +
    geom_point() +
    # labs(x = "x [µm]", y = "y [µm]") +
    # ggtitle(title) +
    theme_bw() +
    theme(
      axis.text = element_text(size = 8),
      plot.title = element_text(size = 8),
      axis.title = element_text(size = 8),
      panel.border = element_rect(size = 1),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.background = element_rect(fill = "white") #
    )

  scatter_plot
}

summary_plot <- function(data_table, summaryplot_name, exp_name = expname, column1 = "numDetectionsCluster", column2 = "areasCluster", column3 = "densitiesCluster") {
  plot_num_area_density <- scatterplot(data_table, column1, column2, column3)
  plot_num_density_area <- scatterplot(data_table, column1, column3, column2)
  plot_area_density_num <- scatterplot(data_table, column2, column3, column1)

  summaryplot <- ggarrange(plot_num_area_density, plot_num_density_area, plot_area_density_num, nrow = 1)
  plot_save(summaryplot, exp_name, summaryplot_name, plot_height = 45, plot_width = 300)
}
