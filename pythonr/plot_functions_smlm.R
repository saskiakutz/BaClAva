# Title     : SMLM simulation plotting
# Objective : Plotting of the underlying molecules
# Written by: Roman Svetlitckii, Saskia Kutz

mol_plotting <- function(size_x,
                         size_y,
                         mol_clusters,
                         positions_mol_cluster,
                         mol_background,
                         dist_background,
                         n_clusters,
                         cluster_centers,
                         dir_output,
                         number_simulation
) {
  # create an image with molecules
  Red <- matrix(0, size_x * 10, size_y * 10)
  Green <- matrix(0, size_x * 10, size_y * 10)
  Blue <- matrix(0, size_x * 10, size_y * 10)

  # molecules in clusters are red
  for (i in 1:mol_clusters) Red[(positions_mol_cluster[i,][1] * 10 + 1),][positions_mol_cluster[i,][2] * 10 + 1] <- 255

  # background molecules are white
  if (mol_background) {
    for (i in 1:mol_background) {
      Red[(dist_background[i,][1] * 10 + 1),][dist_background[i,][2] * 10 + 1] <- 255
      Green[(dist_background[i,][1] * 10 + 1),][dist_background[i,][2] * 10 + 1] <- 255
      Blue[(dist_background[i,][1] * 10 + 1),][dist_background[i,][2] * 10 + 1] <- 255
    }
  }

  # clusters' centers are blue
  for (i in 1:n_clusters) {
    Red[(cluster_centers[i,][1] * 10 + 1),][cluster_centers[i,][2] * 10 + 1] <- 0
    Green[(cluster_centers[i,][1] * 10 + 1),][cluster_centers[i,][2] * 10 + 1] <- 255
  }

  pdf(paste0(dir_output, '/', number_simulation, '/', 'Image_with_molecules.pdf'), width = size_x * 10, height = size_y * 10)
  plot(c(0, size_x * 10), c(0, size_y * 10)) #, xaxt = "i", yaxt = "n")
  axis(1, at = seq(0, size_x * 10, by = 10)) #xaxp = seq(0, (SizeX*10)-1, by = 10))
  # , yaxp = seq(0, SizeY*10, by = 10),
  Output_Image <- rgb(Red, Green, Blue, maxColorValue = 255)
  dim(Output_Image) <- c(size_x * 10, size_y * 10)
  grid.raster(Output_Image)
  dev.off()
}




