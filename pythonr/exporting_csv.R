# Title     : exporting csv in module 3
# Objective : Creating and storage post processing summaris as csv in module 3
# Written by: Saskia Kutz

creating_tibble <- function (results, storage_directory){
  df_long <- dplyr::tibble(
    id = purrr::map(results, 'id'),
      radius = purrr::map(results, 'radii'),
      number_mols = purrr::map(results, 'nmols'),
      area = purrr::map(results, 'area'),
      density = purrr::map(results, 'density'),
      density_area = purrr::map(results, 'density_area')
    ) %>%
      mutate(
        radius = purrr::map(radius, ~ tibble(radius = .x)),
        number_mols = purrr::map(number_mols, ~ tibble(number_mols = .x)),
        area = purrr::map(area, ~ tibble(area = .x)),
        density = purrr::map(density, ~ tibble(density = .x)),
        density_area = purrr::map(density_area, ~ tibble(density_area = .x))
      ) %>%
      tidyr::unnest(cols = c(id, radius, number_mols, area, density, density_area))

  write.csv(df_long, file.path(paste0(storage_directory, '/postprocessing_summary_based_on_clusters.csv')))

  df_short <- dplyr::tibble(
    id = purrr::map(results, 'id'),
      number_clusters = purrr::map(results, 'nclusters'),
      percentage_clusters = purrr::map(results, 'pclustered'),
      total_number_molecules = purrr::map(results, 'totalmols'),
      relative_density = purrr::map(results, 'reldensity')
    ) %>%
      tidyr::unnest(cols = c(id, number_clusters, percentage_clusters, total_number_molecules,
    relative_density))

  write.csv(df_short, file.path(paste0(storage_directory, '/postprocessing_summary_based_on_rois.csv')))
}