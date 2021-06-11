# Title     : Exporting to hdf5
# Objective : Exporting datasets and metadata to an existing hdf5 file
# Written by: Saskia Kutz

write_df_hdf5 <- function(hdf5_file, dataset, dataset_name) {
  # write dataset to hdf5

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
write_metadata_df <- function(hdf5_file, dataset_attr, dataset_name, metadata_name) {
  ds <- H5Dopen(hdf5_file, dataset_name)
  h5writeAttribute(ds, attr = dataset_attr, name = metadata_name)
  H5Dclose(ds)
}

# create a group within a hdf5 file
create_hdf5group <- function(hdf5_file, group_name) {
  tryCatch({
    h5createGroup(hdf5_file, group_name) },
    error = function(e) {
      h5delete(hdf5_file, group_name)
      h5createGroup(hdf5_file, group_name) },
    warning = function(w) { w }
  )
}
