# Title     : Import csv/txt export hdf5
# Objective : Convert csv/txt to hdf5
# Written by: Saskia Kutz

convert_hdf5 <- function(directory, convert_list) {
  # converting csv/txt file to the "data" dataset in a hdf5 file
  # hdf5 file gets the same name as the csv/txt file

  source("./pythonr/package_list.R")
  for (file in convert_list) {
    df <- read.csv(file.path(directory, file))
    df_base <- str_split(file, "\\.")[[1]][1]
    filename <- file.path(directory, paste0(df_base, '.h5'))

    if (file.exists(filename)) file.remove(filename)
    handle <- h5createFile(filename)
    tryCatch(
    {
      h5write(df, filename, "data") },
      error = function(e) {
        h5delete(filename, "data")
        h5write(df, filename, "data")
      }

    )
    file <- H5Fopen(filename)
    did <- H5Dopen(file, 'data')
    h5writeAttribute(did, attr = names(df), name = 'colnames')
    H5Dclose(did)
    H5Fclose(file)

  }
  h5closeAll()
}
