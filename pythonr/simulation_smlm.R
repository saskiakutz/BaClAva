# Title     : SMLM simulation
# Objective : creation of TIFF stack/files of SMLM-like experiments
# Created by: Roman, Saskia
# Created on: 2021-05-06

# this function creates a tiff stack(or single tiffs) with distributed PSFs
#
# input:
# 1) SizeX, SizeY in pixels is the matrix size
# 2) indent is a black rim around the matrix. it is a part of a SizeX*SizeX matrix, not an extra area!
# 2a) pixel_size can in set in nm.
# 3) cluster radius is measured in nm.
# 4) distance_between_clusters is measured in nm.
# 5) FWHM(Full width at half maximum) measured in nm. Defines the PSF's gauss distribution.
# 6) max_intensity is for the largest color value of PSF.
# 7) on, off: probabilities of a molecule to be turned on/off per frame
# 8) frames: number of frames(single tiffs or all in a stack)
# 9) noise: gamma(1) or no noise(0), if omitted gamma is taken
# 10)density_or_molecules: 1 is for input as density, 0 as number of molecules and mean with SD
#    for clusters see below 9)
# 11)clusters_density and background_density are measured as 'number_of_molecules/um^2'
# 12)cluster_mean, cluster_SD: measured in molecules. mean number of mols per cluster and SD is a deviation from mean.
#    there will be totally number_of_clusters*mean_cluster molecules
# 13)molecules_background: nothing interesting just a total number of molecules in background.
#    these will NOT be placed in clusters.
# 14)!gamma for psf centers!iscoming
# 15) directory where the data is supposed to be stored
#
# distance between molecules in background is possible, but set by default to zero


make_plot <- function(SizeX, SizeY, indent, pixel_size,
                      number_of_clusters, cluster_radius, distance_between_clusters,
                      FWHM, max_intensity, on, off, frames, simulations, stack_or_single, noise,
                      density_or_molecules = 1, clusters_density, background_density,
                      cluster_mean, cluster_SD, molecules_background, directory_folder)
{
  source('./pythonr/package_list.R')
  source('./pythonr/internal_smlm_simulation.R')
  source('./pythonr/plot_functions_smlm.R')
  #--------------------------------------error handling-------------------------------------------------#
  if (SizeX < 20 ||
    SizeY < 20 ||
    SizeX > 250 ||
    SizeY > 250) stop("SizeX and SizeY mist be in [20,250]")

  number_of_clusters <- floor(number_of_clusters)
  if (number_of_clusters < 1 || number_of_clusters > 200) stop("number_of_clusters must be within [1,200]")

  if (missing(cluster_radius)) stop("cluster_radius is missing. Choose from [1,500]. Measured in nm.")
  if (cluster_radius < 1 || cluster_radius > 500) stop("cluster_radius is not valid. Choose from [1,500]. Measured in nm.")

  if (missing(distance_between_clusters)) stop("distance_between_clusters is missing. Choose from [0,1000]. Measured in nm")
  if (distance_between_clusters < 0 || distance_between_clusters > 1000) stop("Valid range for distance_between_clusters is [1,1000]. Measured in nm")
  distance_between_clusters <- distance_between_clusters / 100 # transform to pixels

  if (missing(FWHM)) {
    print("FWHM was not defined. It will be 450 nm then.")
    FWHM <- 450 / pixel_size
  }

  if (FWHM < pixel_size || FWHM > 4000) stop("FWHM must be in [pixel size,4000]")
  FWHM <- FWHM / pixel_size
  SD <- FWHM / 2.355
  if (indent < ceiling(SD * 3.1)) {
    indent <- ceiling(SD * 3.1)
    print(paste0("indent will be:", indent))
  }

  # max_intensity is taken from storm data(alexa 647)
  if (max_intensity < 534 || max_intensity > 5262) stop("max_intensity must be in [534,5262]")
  spare_max_intensity <- max_intensity # for meta
  max_intensity <- floor(max_intensity / bivariate_normal_distribution(0, 0, SD)) # scale it

  if (on <= 0 || on > 0.1) stop("on probability must be in (0,0.1]")
  if (off < 0 || off > 1) stop("off probability must be in [0,1]")

  frames <- floor(frames)
  if (frames < 1 || frames > 100000) stop("number of frames must be in range 1-50000")

  simulations <- floor(simulations)
  if (simulations < 1 || simulations > 200) stop("simulations must be in [1,200]")

  if ((SizeX * SizeX * 2 + 66) * frames + 74 > 300000000) {
    if (((SizeX * SizeX * 2 + 66) * frames + 74) / 1000000000 >= 5) {
      print(paste0("You crazy! i won't create", ((SizeX * SizeX * 2 + 66) * frames + 74) / 1000000000, "Gb. You can change the code though to get rid of that disobedience."))
      return(0)
    }
    print(paste0("you can not create a stack of size ", (SizeX * SizeX * 2 + 55) * frames / 1000000000, " Gb"))
    print("Max size is 300 Mb")
    print("if you disagree with that delete 'return(0)' in make_plot(). You can find this string with ctrl+F there. But be carefull, you will have to either create only single tiffs or modify Stack writing(write every 1000 frames for instance).")
    return(0)
  }

  # noise == 1 for gamma, noise == 0 for absence of any noise
  if (missing(noise)) noise <- 1
  if (noise != 0 && noise != 1) {
    print("Valid values for noise are: 1 for gamma and 0 for no noise")
    print("Since you wrote something different from the values mentioned above, gamma noise will be used")
    noise <- 1
  }

  if (missing(stack_or_single)) stack_or_single <- 1
  if (stack_or_single != 0 && stack_or_single != 1) {
    print("Valid values for stack_or_single are: 1 for stack and 0 for single.")
    print("Since you wrote something different from the values mentioned above, stack will be created")
    stack_or_single <- 1
  }

  if (missing(density_or_molecules)) stop("density_or_molecules is not specified. Please select 1 for density or 0 for molecules")
  if (density_or_molecules != 0 && density_or_molecules != 1) stop("allowed values for density_or_molecules are: 1 for density or 0 for molecules")

  if (density_or_molecules) {
    if (missing(clusters_density)) stop("Select a clusters_density. Choose from [200,20000]. clusters_density is measured in 'number of molecules/um^2'")
    if (clusters_density < 200 || clusters_density > 20000) stop("clusters_density must be in [200,20000]. Measured in 'number of molecules/um^2'")

    if (missing(background_density)) stop("background_density is missing. Please select one from [0,20000]. Measured in 'molecules/um^2'.")
    if (background_density < 0 || background_density > 20000) stop("invalid background_density value. Please select one from [0,20000]. Measured in 'molecules/um^2'.")

    # 1um^2 = 10^6nm^2 = 10x10 pixels, 1pixel = 100nm
    molecules_in_clusters <- round(clusters_density *
                                     (2 * pi * cluster_radius^2) *
                                     number_of_clusters *
                                     10^-6)
    print(paste0("number of molecules in clusters:", molecules_in_clusters))
    if (molecules_in_clusters < number_of_clusters) {
      Out_error <- paste0(paste0("there too few molecules_in_clusters:", molecules_in_clusters), paste0("number of clusters:", number_of_clusters), "please make a cluster's density larger or adjust cluster_radius with number_of_clusters", sep = "\n")
      stop(Out_error)
    }

    cluster_mean <- floor(molecules_in_clusters / number_of_clusters)
    cluster_SD <- floor(cluster_mean / 5)
    if (cluster_mean < 3) print(paste0("cluster_mean is", cluster_mean, ".Weird result is possible."))

    if (molecules_in_clusters == 0) stop("molecules_in_clusters = 0, please change the input(cluster radius or density)")
  }
  else {
    if (missing(cluster_mean)) stop("cluster_mean is missing. Select one from [1,1000]. Measure in molecules.")
    if (cluster_mean < 5 || cluster_mean > 1000) stop("valid range for cluster_mean is [5,1000]")

    cluster_mean <- floor(cluster_mean)
    molecules_in_clusters <- number_of_clusters * cluster_mean

    if (missing(cluster_SD)) {
      print("cluster_SD is missing. all clusters will have the same number of molecules.")
      cluster_SD <- 0
    }
    if (cluster_SD < 0 || cluster_SD > 100) stop("cluster_SD is not valid. Take one from (0,100]")

    if (missing(molecules_background)) {
      print("molecules_background parameter was not definied. 0 is set.")
      molecules_background <- 0
    }
    if (molecules_background < 0 || molecules_background > 1000000) stop("molecules_background must be in [0,1000000]")
    # molecules_background <- floor(molecules_background)
  } #------------------------------------------------------------------------#

  cluster_radius <- cluster_radius / pixel_size

  output_directory <- paste0(frames, "frames_", clusters_density, "clus density_", background_density, "back density_",
                             cluster_radius, "nm clusradius_", round(100 * distance_between_clusters, 2), "nm distance between clusters_",
                             "mols in clusters", molecules_in_clusters, sep = '')

  if (0 && file.exists(file.path(directory_folder, output_directory)))
  {
    print("Warning:")
    print(paste0("following directory already exists:", output_directory))
    answer <- readline(prompt = "Should it be removed(y/n): ")
    if (answer != '' && length(grep(answer, "Yes", ignore.case = TRUE))) {
      unlink(output_directory, recursive = TRUE)
      print("Directory was deleted")
    }
    else {
      print("Directory was not removed")
      return(0)
    }
  }
  unlink(output_directory, recursive = TRUE) ###!!!!!
  dir.create(file.path(directory_folder, output_directory))

  # create a matrix of a circle, it will be used to create PSF
  # only entries equal to 1 are within a PSF(circle)
  PSF <- ceiling(SD * 3)
  Circle <- matrix(0, PSF * 2 + 1, PSF * 2 + 1)
  for (x in -PSF:PSF) {
    for (y in -PSF:PSF) {
      if (sqrt(abs(x)^2 + abs(y)^2) <= PSF) Circle[x + PSF + 1,][y + PSF + 1] <- 1
    }
  }
  PSF_range <- PSF:-PSF # from positive to negative for proper calculation of a distznce to the neighbour-pixels

  radius_x <- NULL
  for (x in -PSF:PSF) radius_x <- c(radius_x, rep(x, (PSF * 2 + 1)))
  #radius_y <- rep(PSF_range,(PSF*2+1))

  Frame <- matrix(0, SizeX, SizeY)

  n_sim <- 1
  while (n_sim <= simulations)
  {
    start_time <- Sys.time()

    clusters_centers <- distribute_clusters_uniform(number_of_clusters, cluster_radius, SizeX, SizeY, indent, distance_between_clusters)
    mol_array <- distribute_molecules_in_clusters(cluster_mean, cluster_SD, number_of_clusters, molecules_in_clusters)

    cluster_mols_positions <- matrix(0, molecules_in_clusters, 2)

    # distribute molecules' positions in clusters
    clusters_radiuses <- NULL
    current_index <- 1

    # third column is used for testing a deviance of a calculated radius from the 'cluster_radius'.
    clusters_centers <- cbind(clusters_centers, rep(1, number_of_clusters))
    extra_protection <- 0
    deviation_percent <- 0.001

    # as long as there ones in the third column do the mols distribution
    while (is.element(1, clusters_centers[, 3]))
    {
      extra_protection <- extra_protection + 1

      for (i in 1:number_of_clusters)
      {
        if (clusters_centers[i,][3])
        { out <- distribute_molecules_in_cluster_gauss(clusters_centers[i,][1], clusters_centers[i,][2], mol_array[i], cluster_radius) }
        else next

        if (cluster_radius - out$True_radius <= cluster_radius * deviation_percent)
        {
          cluster_mols_positions[current_index:(current_index - 1 + mol_array[i]),] <- out$Molecule_positions
          clusters_radiuses <- c(clusters_radiuses, out$True_radius)
          current_index <- current_index + mol_array[i]
          clusters_centers[i,][3] <- 0
        }
      }

      # increase the deviation_percent if it did not work with the previous one
      if (extra_protection == 1000000) {
        deviation_percent <- deviation_percent + 0.001
        extra_protection <- 0
      }
    }

    clusters_centers <- clusters_centers[, -3] # delete the third column

    clusters_density <- molecules_in_clusters / (sum((100 * clusters_radiuses)^2 * pi * 2) * 10^-6)

    # calculate the number of background molecules and distribute them
    background_area <- 100 *
      (SizeX - 2 * indent) *
      100 *
      (SizeY - 2 * indent) - sum((100 * clusters_radiuses)^2 * pi)
    molecules_background <- floor(background_density * background_area * 10^-6)

    #if (molecules_background < 500) warning(paste0("there are totally", molecules_background, "molecules in background"))

    print(paste0("number of molecules in background:", molecules_background))

    rest <- distribute_background_molecules_uniform(SizeX, SizeY, indent, clusters_centers, clusters_radiuses, molecules_background, 0)

    # Bind background and clusters together and add a third column for blinking(1-on, 0-off; at the beginning everything is off)
    #
    # This third column can be used for other purposes as well:
    # For example: the LSF can mark blinking(on or off) and the second bit(left from LSF) can be used for bleaching.
    # The other bits can be also used for something.
    if (length(rest)) mols <- rbind(cluster_mols_positions, rest)
    else mols <- cluster_mols_positions
    n_mols <- molecules_background + molecules_in_clusters
    mols <- cbind(mols, matrix(0, n_mols, 1))

    if (stack_or_single) Stack <- list() # create a list which will contain stack frames
    dir.create(paste0(file.path(directory_folder, output_directory), '/', n_sim))

    print("Molecules' positions are distributed")
    print(paste0("Total number of frames: ", frames))
    print(paste0("creating frames for a ", n_sim, '/', simulations, " simulation..."))

    # just a little quirk:
    # changing "while (n_frame <= frames)" to "for (n_frame in 1:frames)" throws sometimes an error in bitwAnd() in write_tiff() on R version 4.0.5
    n_frame <- 1
    while (n_frame <= frames)
    {
      # fill the matrix with random rayleigh noise:
      # distribution's scale = 1.0769
      # x scale = 129.8, rayleigh was fitted to x [0,10], real data would have over 1000 values for noise
      # +373 shifts in the valid color space, Min color intensity value was 339
      # Frame[0:SizeX,] <- floor(((1.0769*(-2*log(runif(SizeX*SizeY)))**0.5)*129.8)+339)

      if (noise) Frame[0:SizeX,] <- floor(rgamma(SizeX * SizeY, shape = 20.8, scale = 0.1) * 25.21 + 351)
      else Frame[0:SizeX,] <- 0

      # molecules are randomly turned on/off
      mols[, 3] <- ifelse(mols[, 3] == 1, rbinom(sum(mols[, 3] == 1), 1, 1 - off), rbinom(sum(mols[, 3] == 0), 1, on))

      # make sure that the current frame contains PSFs.
      if (!is.element(1, mols[, 3])) next

      mols_on <- mols[, 1:2][mols[, 3] == 1]
      Length <- length(mols_on) / 2
      for (i in 1:Length)
      {
        # matrix indexes start with 1 so positions(start with 0) must be shifted
        X1 <- floor(mols_on[i]) - PSF + 1
        Y1 <- floor(mols_on[i + Length]) - PSF + 1

        # 1 is added because of a middle(y axis shift is 0) "circle layer"
        X2 <- floor(mols_on[i]) + PSF + 1
        Y2 <- floor(mols_on[i + Length]) + PSF + 1

        # deviation of a molecule from pixel's center where it lies
        X_shift <- mols_on[i] - (floor(mols_on[i] + 0.5))
        Y_shift <- mols_on[i + Length] - (floor(mols_on[i + Length] + 0.5))

        Frame[X1:X2,][, Y1:Y2] <- Frame[X1:X2,][, Y1:Y2] +
          Circle * floor(max_intensity * bivariate_normal_distribution(X_shift + radius_x, Y_shift + PSF_range, SD))
      }

      # a tiff's pixel value has only 2 bytes, which means that values > 65535 would overflow
      # if too many molecules would blink simultaneously, then it's possible that they would sum up to >65535
      Frame[Frame > 65535] <- 65535

      # write a single .tiff or append a frame to a stack
      if (stack_or_single) Stack[[n_frame]] <- Frame
      else write_tiff(list(Frame), paste0(file.path(directory_folder, output_directory), '/', n_sim, '/', n_frame, '.tiff', sep = ''))

      n_frame <- n_frame + 1
    }

    if (stack_or_single) {
      print("all frames are done")
      print("creating tiff...")
      write_tiff(Stack, paste0(file.path(directory_folder, output_directory), '/', n_sim, '/', n_sim, '.tiff'))
    }
    else print("all tiffs are created")

    mol_plotting(size_x = SizeX,
                 size_y = SizeY,
                 mol_clusters = molecules_in_clusters,
                 positions_mol_cluster = cluster_mols_positions,
                 mol_background = molecules_background,
                 dist_background = rest,
                 n_clusters = number_of_clusters,
                 cluster_centers = clusters_centers,
                 dir_output = file.path(directory_folder, output_directory),
                 number_simulation = n_sim
    )

    meta_file <- paste0(file.path(directory_folder, output_directory), '/', n_sim, '/', 'meta.txt')
    write(paste0('"Summary": {\n"Total number of molecules": ', n_mols, ',\n"Molecules in clusters": ', molecules_in_clusters, ',\n"Molecules in background": ', molecules_background,
                 ',\n"Frames": ', frames, ',\n"Height": ', SizeY, ',\n"Width": ', SizeX, ',\n"Indent": ', indent, ',\n"FWHM": ', 100 * FWHM, 'nm,\n"Max color intensity": ',
                 spare_max_intensity, ',\n"Clusters density(molecules per um^2)": ', clusters_density, ',\n"Background density(molecules per um^2)": ',
                 background_density, ',\n"Noise": ', ifelse(noise, '"Gamma"', '"No noise"'), ',\n"Number of clusters": ', number_of_clusters, ',\n"Max cluster radius": ',
                 100 * cluster_radius, 'nm,\n"Distance_between clusters": ', 100 * distance_between_clusters,
                 'nm,\n"PixelType": "GRAY16",\n"Exposure-ms": 20,\n"On rate(per frame)": ', on, ',\n"Off rate(per frame)": ', off,
                 ',\n"Camera": "Evolve",\n"PVCAM-CameraHandle": "0",\n"Core-Camera": "Evolve",\n"PVCAM-CameraHandle": "0",\n}', sep = ''), meta_file)
    write("\nClusters' info(position x, position y, number of molecules, radius(nm)):", meta_file, append = TRUE)
    clusters_centers <- clusters_centers[order(clusters_centers[, 1]),]
    for (pos in 1:number_of_clusters) write(paste0(round(clusters_centers[pos,][1], 3), round(clusters_centers[pos,][2], 3), mol_array[pos], round(100 * clusters_radiuses[pos], 3)), meta_file, append = TRUE)
    print("Total creation time: ")
    print(Sys.time() - start_time)
    n_sim <- n_sim + 1
  }
}
