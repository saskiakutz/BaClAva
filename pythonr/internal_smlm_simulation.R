# Title     : internal functionalities for SMLM simulation
# Objective : simulation of clusters of molucules and their blinking behaviour
# Created by: Roman, Saskia
# Created on: 2021-05-06

# This function distributes centers of clusters
#
# Input:
# 1) cluster_radius(in pixels, 1 pixel = 100nm) is used to properly place the centers
# 2) SizeX and SizeY determine the matrix size
# 3) indent is used for a void rim around the matrix
# 4) distance_between_clusters in pixels, 1 pixel = 100nm
#
# Output:
# an Array with randomly(uniformly) distributed centers(x,y) of clusters


distribute_clusters_uniform <- function(number_of_clusters,
                                        cluster_radius,
                                        SizeX, SizeY, indent,
                                        distance_between_clusters) {

  # error handling
  if (number_of_clusters <= 1 || number_of_clusters > 300) stop("number_of_clusters must be in range 2-300")
  number_of_clusters <- floor(number_of_clusters)

  if (SizeX < 20 ||
    SizeY < 20 ||
    SizeX > 500 ||
    SizeY > 500) stop("SizeX and SizeY must be in range 20-500")
  SizeX <- floor(SizeX)
  SizeY <- floor(SizeY)

  if (indent < 0) stop("indent must be positive")
  indent <- floor(indent)

  if (cluster_radius < 0) stop("cluster_radius must be positive")

  if (distance_between_clusters < 0 || max(SizeX, SizeY) -
    2 * indent -
    2 * cluster_radius < distance_between_clusters)
  { stop("distance between clusters must be positive and smaller then 'max(SizeX,SizeY)-(2*indent+2*cluster_radius)'.
   Make a matrix bigger or a cluster_radius smaller.") }

  if (distance_between_clusters < cluster_radius * 2)
  { warning("if distance_between_clusters < cluster_radius*2, then some molecules can belong to several clusters") }

  X1 <- indent + cluster_radius
  X2 <- SizeX - cluster_radius - indent
  Y1 <- indent + cluster_radius
  Y2 <- SizeY - cluster_radius - indent

  if (X1 >= X2 || Y1 >= Y2) stop("indent or cluster_radius is too large")

  #if (floor((X2-X1)/distance_between_clusters+1) * floor((Y2-Y1)/distance_between_clusters+1) < number_of_clusters )
  #{ stop("It wont work. There is not enough space.
  # Try to reduce distance_between_clusters or cluster_radius or make a matrix larger") }
  #-----------------------------------------------#

  cluster_centers <- matrix(0, number_of_clusters, 2)

  cluster_centers[1,] <- c(runif(1, min = X1, max = X2), runif(1, min = Y1, max = Y2))

  # since there are enough problematic cases(mostly because of the "distance_between_clusters"),
  # some "extra protection" will be used
  # just to be sure that a procedure call will terminate
  start_again <- number_of_clusters * 100
  steps_made <- 0
  real_stop <- 0

  i = 1

  while (i < number_of_clusters)
  {
    if (real_stop == 10) {
      print(paste("results of distributing the centers of clusters will be different from input.
      Distance between clusters will be smaller than:", distance_between_clusters))
      cluster_centers[, 1] <- runif(number_of_clusters, min = X1, max = X2)
      cluster_centers[, 2] <- runif(number_of_clusters, min = Y1, max = Y2)
      return(cluster_centers)
    }

    if (steps_made == start_again) {
      i <- 1
      steps_made <- 0
      cluster_centers <- matrix(0, number_of_clusters, 2)
      cluster_centers[1,] <- c(runif(1, min = X1, max = X2), runif(1, min = Y1, max = Y2))
      real_stop <- real_stop + 1
    }

    cluster_centers[i + 1,] <- c(runif(1, min = X1, max = X2), runif(1, min = Y1, max = Y2))

    for (k in 1:i)
    {
      steps_made <- steps_made + 1
      if (steps_made == start_again ||
        sqrt(abs(cluster_centers[k,][1] - cluster_centers[i + 1,][1])^2 +
               abs(cluster_centers[k,][2] - cluster_centers[i + 1,][2])^2)
          < distance_between_clusters)
      { i <- i - 1
        break }
    }
    i <- i + 1
  }

  return(cluster_centers)
}


#--------------------------------------------------------------------------------#


# this function creates distributes(gauss) molecules in clusters(decides how many molecules each cluster will have)
# in the end there are "number_of_clusters*cluster_mean" molecules total in all clusters
#
# Input:
# 1) cluster_mean is a gauss mean(mean number of molecules per cluster)
# 2) cluster_SD is a standart deviation("measured" in molecules) for gauss
# 3) molecules_in_clusters is optional, if not given there are total: 'cluster_mean*number_of_clusters' molecules
#
# Output:
# an array, each entry corresponds to a number of molecules per cluster.
# there is no garantee that an output will be gauss distributed,
# one can find such parameters which make it very hard to get it gauss-like

distribute_molecules_in_clusters <- function(cluster_mean, cluster_SD, number_of_clusters, molecules_in_clusters) {


  # error handling
  if (number_of_clusters < 1 || number_of_clusters > 1000) stop("number_of_clusters must be in range 1-1000")
  number_of_clusters <- floor(number_of_clusters)

  if (cluster_mean < 1 || cluster_mean > 1000) stop("cluster_mean must be in range 1-1000")
  cluster_mean <- floor(cluster_mean)

  if (cluster_SD < 0) stop("cluster_SD must positive or zero")

  if (cluster_mean < cluster_SD * 3) {
    warning("cluster_mean < cluster_SD*3. SD will be changed")
    cluster_SD <- floor(cluster_mean / 3)
    print(paste("cluster_SD is:", cluster_SD))
  }

  if (missing(molecules_in_clusters)) molecules_in_clusters <- number_of_clusters * cluster_mean
  else {
    molecules_in_clusters <- abs(molecules_in_clusters)
    cluster_mean <- floor(molecules_in_clusters / number_of_clusters)
    cluster_SD <- floor(cluster_mean / 3)
    print(paste("cluster_mean will be:", cluster_mean))
    print(paste("cluster_SD will be:", cluster_SD))
  }

  number_of_molecules <- number_of_clusters * cluster_mean
  molecules_in_clusters_rest <- molecules_in_clusters - number_of_molecules

  if (number_of_molecules == 0 || cluster_mean == 0) return(c())

  mol_array <- c()
  if (cluster_SD == 0) mol_array <- rep(1, number_of_clusters)

  #if (molecules_in_clusters_rest < 0) stop("there must be at least cluster_mean*number_of_clusters molecules")
  #if (molecules_in_clusters_rest != 0){
  #	warning("mean number and SD of molecules in clusters will be different from the input")

  #}
  # because molecules are distributed randomly it can happen that a result would be wrong,
  # so we have to start distributing again
  # some sort of protection from an endless loop is needed
  threshold <- 0.01
  steps_made <- 0
  real_stop <- 0
  mol_boundary <- floor(cluster_SD * 3) # used to limit the deviation from mean

  while (cluster_SD && 1)
  {
    # increase threshold if it did not work out with the previous threshold value
    if (steps_made == 1000)
    {
      threshold <- threshold * 2
      steps_made <- 0
      real_stop <- real_stop + 1

      # if parameters are chosen so that it can not be distributed the way we want it to, then we break out of a loop
      if (real_stop == 1000) break
    }

    mol_array <- c()

    # fill an array with values
    number_of_molecules_i <- number_of_molecules

    while (cluster_mean + mol_boundary < number_of_molecules_i)
    {
      mol_n <- round(rnorm(1, cluster_mean, cluster_SD))   # choose randomly some number of molecules

      if (mol_n < 1) next                                # a case of producing negative number of molecules or zero

      if (abs(mol_n - cluster_mean) > mol_boundary) next   # if it exceeds a mol_boundary
      else
      {
        mol_array <- c(mol_array, mol_n)
        number_of_molecules_i <- number_of_molecules_i - mol_n
      }
    }

    # the rest
    if (number_of_molecules_i > 0)
    {
      # within boundries
      if (abs(number_of_molecules_i - cluster_mean) < mol_boundary) mol_array <- c(mol_array, number_of_molecules_i)

        # or not(under cluster_mean-mol_boundary)
      else next
    }

    # check the results
    if (abs(mean(mol_array) - cluster_mean) > threshold ||
      sum(mol_array) != number_of_molecules ||
      number_of_clusters != length(mol_array)) {
      steps_made <- steps_made + 1 # if a result is not satisfying increase the steps_made
      next
    }
    break
  }

  rest_positions <- floor(runif(molecules_in_clusters_rest, 1, number_of_clusters + 1))
  for (i in rest_positions) mol_array[i] <- mol_array[i] + 1

  if (real_stop == 1000) print("The output of distribute_molecules_in_clusters() will most probably differ from what you expect")

  return(mol_array)
}

#-----------------------------------------#


# Binary search for a matrix
# undefinied behavior if an input-matrix(first column(x-positions)) is not sorted
#
# output: a pair with 2 positions, which contain the closest numbers to input "number"
# "number" is either between Left und Right(if there are numbers smaller and larger as "number")
# or (Left,Right) = (1,2), if the smallest number in the matrix is larger then "number"
# or (Left,Right) = (number_of_matrix_columns-1, number_of_matrix_columns), if the largest number in the matrix is smaller then "number"

binary_search <- function(Matrix, number) {

  Right <- dim(Matrix)[1]
  Left <- 1
  while (Right - Left > 1)
  {
    Center <- ceiling((Right + Left) / 2)
    if (number < Matrix[Center,][1]) Right <- Center
    else Left <- Center
  }
  return(c(Left, Right))
}

# this function distributes background molecules on a matrix
#
# Input:
# 1) SizeX and SizeY: matrix size
# 2) indent: an area around matrix which contains no molecules
# 3) clusters_centers: a matrix with clusters' centers   +
#														  > these 2 are used to place background molecules outside clusters
# 4) clusters_radiuses: an array with clusters' radiuses +
# 5) number_of_molecules: number of background molecules
# 6) distance: distance between molecules in pixels, 0 by default. Can be used to make molecules look more homogeneous.
#
# Output:
# a matrix with background molecules' positions(x,y)

distribute_background_molecules_uniform <- function(SizeX, SizeY, indent,
                                                    clusters_centers,
                                                    clusters_radiuses,
                                                    number_of_molecules,
                                                    distance) {

  # error checking
  if (SizeX < 20 ||
    SizeX > 500 ||
    SizeY < 20 ||
    SizeY > 500) stop("Sizes of X and Y must be in range 20-500")
  SizeX <- floor(SizeX)
  SizeY <- floor(SizeY)

  if (indent < 0) stop("indent must be at least zero")
  indent <- floor(indent)

  if (missing(clusters_centers)) stop("matrix with clusters_centers is missing")
  if (missing(clusters_radiuses)) stop("vector with clusters_radiuses is missing")

  if (dim(clusters_centers)[1] != length(clusters_radiuses)) stop("clusters_centers and clusters_radiuses have different lengths")

  if (number_of_molecules < 0) stop("number_of_molecules can not be negative")
  number_of_molecules <- floor(number_of_molecules)
  if (!number_of_molecules) return(matrix(0, 0, 0))

  if (missing(distance)) distance <- 0
  if (distance < 0 || distance > 4) stop("distance must be in range 0-4")
  #-----------------------------------------------#

  X1 <- indent
  X2 <- SizeX - indent
  Y1 <- indent
  Y2 <- SizeY - indent

  if (X1 >= X2 || Y1 >= Y2) stop("indent is too large")

  if (distance && (sqrt((X2 - X1) * (Y2 - Y1) - sum(clusters_radiuses^2 * pi)) / distance + 1)^2 < number_of_molecules)
  { stop("There is definitely not enough space for molecules. Try to reduce the distance or enlarge the matrix.") }
  if (distance && (sqrt((X2 - X1) * (Y2 - Y1) - sum(clusters_radiuses^2 * pi)) / distance + 1)^2 * 0.55 < number_of_molecules)
  { print("Warning: it is probably going to be hard to distribute molecules with the given distance.
  It is gonna take some time to find that out. No guarantee that it will work.") }

  # protection from looping forever(can happen only if distance > 0)
  stop_counter <- 0
  real_stop <- 0

  mol_array <- matrix(0, number_of_molecules, 2)
  clusters_centers <- clusters_centers[order(clusters_centers[, 1]),] # sort the matrix by x column
  Number_of_clusters <- length(clusters_radiuses)
  i <- 1

  while (i <= number_of_molecules)
  {
    if (stop_counter == 150)
    {
      mol_array[1:number_of_molecules,] <- 0
      i <- 1
      real_stop <- real_stop + 1
      if (real_stop == 10)
      {
        print("It was not possible to distribute molecules. Try to lower a distance or number_of_molecules. Making a matrix larger would also help.")
        return(0)
      }
    }


    mol_array[i,] <- c(runif(1, X1, X2), runif(1, Y1, Y2))

    # find out the nearest clusters to a new molecule
    Left_Right <- binary_search(clusters_centers, mol_array[i,][1])
    Left <- Left_Right[1]
    Right <- Left_Right[2]
    is_fine <- TRUE

    # first check if a new molecule is within a cluster, if so then it must be "thrown away"
    # check  the distance to the left "neighbors"
    while (is_fine &&
      (Left >= 1) &&
      (abs(clusters_centers[Left,][1] - mol_array[i,][1]) < clusters_radiuses[Left]))
    {
      # check the distance at the y axis first, just to avoid calling sqrt()
      if (abs(clusters_centers[Left,][2] - mol_array[i,][2]) < clusters_radiuses[Left]) {
        if (sqrt(abs(clusters_centers[Left,][1] - mol_array[i,][1])^2 +
                   abs(clusters_centers[Left,][2] - mol_array[i,][2])^2) < clusters_radiuses[Left]) is_fine <- FALSE
      }
      Left <- Left - 1
    }

    # and to the right ones
    while (is_fine &&
      (Right <= Number_of_clusters) &&
      (abs(clusters_centers[Right,][1] - mol_array[i,][1]) < clusters_radiuses[Right]))
    {
      if (abs(clusters_centers[Right,][2] - mol_array[i,][2]) < clusters_radiuses[Right]) {
        if (sqrt(abs(clusters_centers[Right,][1] - mol_array[i,][1])^2 +
                   abs(clusters_centers[Right,][2] - mol_array[i,][2])^2) < clusters_radiuses[Right]) is_fine <- FALSE
      }
      Right <- Right + 1
    }


    # compare the molecules' positions to a new one
    # here a special case
    if (i == 2 && distance && is_fine) {
      if (sqrt(abs(mol_array[1,][1] - mol_array[2,][1])^2 +
                 abs(mol_array[1,][2] - mol_array[2,][2])^2) < distance) is_fine <- FALSE
    }

    if (distance && is_fine && i > 2)
    {
      # sort the numbers with indexes 1:(i-1) in the matrix "mol_array" and find out where the new molecule lies
      mol_array[1:(i - 1),] <- mol_array[order(mol_array[1:(i - 1),][, 1]),]

      Left_Right <- binary_search(mol_array[1:(i - 1),], mol_array[i,][1])
      Left <- Left_Right[1]
      Right <- Left_Right[2]

      # look at the neighbors
      while (is_fine &&
        (Left >= 1) &&
        (abs(mol_array[Left,][1] - mol_array[i,][1]) < distance))
      {
        # check first if the distance on the y axis is large enough to skip a sqrt() call
        if (abs(mol_array[Left,][2] - mol_array[i,][2]) < distance) {
          if (sqrt(abs(mol_array[Left,][1] - mol_array[i,][1])^2 +
                     abs(mol_array[Left,][2] - mol_array[i,][2])^2) < distance) is_fine <- FALSE
        }
        Left <- Left - 1
      }

      # the right ones
      while (is_fine &&
        (Right < i) &&
        (abs(mol_array[Right,][1] - mol_array[i,][1]) < distance))
      {
        if (abs(mol_array[Right,][2] - mol_array[i,][2]) < distance) {
          if (sqrt(abs(mol_array[Right,][1] - mol_array[i,][1])^2 +
                     abs(mol_array[Right,][2] - mol_array[i,][2])^2) < distance) is_fine <- FALSE
        }
        Right <- Right + 1
      }
    }

    if (is_fine) {
      i <- i + 1
      stop_counter <- 0
    }
    else stop_counter <- stop_counter + 1
  }

  # sort it again, because of the last entry
  if (number_of_molecules > 1) mol_array <- mol_array[order(mol_array[, 1]),]

  return(mol_array)
}

# creates a tiff stack
# !appends! matrices(frames) to a file, so if a file already contains something then this function will corrupt it!
# all matrices must have the same size, otherwise undefined behavior
# only necessary tags are added to meta info

# header has an intel endianness and and a magic number(42) plus shifting(offset) to the first IFD(image file directory)
# IFD comes before image data
# IFD has only 5 tags: width, height, BitsPerSample, PhotometricInterpretation, StripOffsets(aka shift to data)
# BitsPerSample is always grey16 as it is in storm data
# look here for more information about tiff structure:  https://www.fileformat.info/format/tiff/corion.htm

write_tiff <- function(matrix_stack, file_out) {

  con <- file(file_out, "ab")
  stack_size <- length(matrix_stack)
  matrix_axis <- dim(matrix_stack[[1]])

  writeBin(as.integer(c(73, 73, 42, 0, 8, 0, 0, 0)), con, size = 1)      # header

  tags <- as.integer(c(5, 0, 0, 1, 3, 0, 1, 0, 0, 0,                        # number of tags(5) and width tag
                       bitwAnd(matrix_axis[1], 255),                # x axis as 4 bytes represented in integers
                       bitwAnd(matrix_axis[1], 65280), 0, 0,

                       1, 1, 3, 0, 1, 0, 0, 0,                            # and a length tag
                       bitwAnd(matrix_axis[2], 255),                # here y axis as 4 bytes
                       bitwAnd(matrix_axis[2], 65280), 0, 0,

                       2, 1, 3, 0, 1, 0, 0, 0, 16, 0, 0, 0,                  # number of bits per pixel(grey16)

                       6, 1, 3, 0, 1, 0, 0, 0, 1, 0, 0, 0,                    # PhotometricInterpretation. Set to 1

                       17, 1, 4, 0, 1, 0, 0, 0))                        # offset to the image data(matrix),
  # but without tag's data(this will be joined later)

  #tags2 <- as.integer(c(22,1,3,0,1,0,0,0,							# RowsPerStrip is equal to the length tag, because it's so in real data
  #					  bitwAnd(matrix_axis[2],255),
  #					  bitwAnd(matrix_axis[2],65280),0,0))

  # offsets[1] to the first image data, it will be "updated" after each added frame and point to the next matrix.
  # This offset is counted in bytes.
  # offsets[2] to the first IFD data, will also point to the next IFD later.
  offsets <- as.integer(c(74, 74 + matrix_axis[1] * matrix_axis[2] * 2))

  i = 1

  while (i <= stack_size) {

    if (i == stack_size)  offsets <- as.integer(c(offsets[1], 0)) # the last IFD pointer should be zero

    writeBin(tags, con, size = 1)
    writeBin(offsets, con, size = 4)
    offsets <- as.integer(offsets +
                            66 +
                            matrix_axis[1] * matrix_axis[2] * 2) # 66 because header was cut off

    writeBin(as.integer(matrix_stack[[i]]), con, size = 2)

    i = i + 1
  }

  close(con)
}

#------------------#

rtruncnorm <- function(x, a, b, mu, sigma) {

  out = c()
  while (x > 0) {
    gg = rnorm(x, mu, sigma)
    gg = gg[gg >= a]
    out = c(out, gg[gg <= b])
    x = x - length(gg[gg <= b])
    if (x == 0) break
  }

  return(out)
}

#------------------#

# correlation(p) is zero, SD and mean are equal, mean is zero
bivariate_normal_distribution <- function(x, y, SD) {
  return(exp(-((x / SD)^2 + (y / SD)^2) / 2) / (2 * pi * SD^2))
}
