# Title     : exporting to hdf5
# Objective : exporting datasets and metadata to an existing hdf5 file
# Created by: saskia Kutz
# Created on: 2021-04-16

# write dataset to hdf5
write_df_hdf5 <- function(hdf5_file, dataset, dataset_name) {
  tryCatch(
  {
    h5write(dataset, hdf5_file, dataset_name) },
    error = function(e) {
      h5delete(hdf5_file, dataset_name)
      h5write(dataset, hdf5_file, dataset_name)
    }
  )
}

# write metadata to dataset (which is not part of a group)
write_metadata_df <- function(hdf5_file, dataset, dataset_name, metadata_name) {
  ds <- H5Dopen(hdf5_file, dataset_name)
  h5writeAttribute(ds, attr = names(dataset), name = metadata_name)
  H5Dclose(ds)
}
