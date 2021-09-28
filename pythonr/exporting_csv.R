# Title     : exporting csv in module 3
# Objective : Creating and storage post processing summaris as csv in module 3
# Written by: Saskia Kutz

creating_tibble <- function (results, storeage_directory){
  df_long <- dplyr::tibble(
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
      tidyr::unnest()

  write.csv(df_long, file.path(paste0(storeage_directory, '/test.csv')))
    # print(results)

  df_short <- dplyr::tibble(
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
      tidyr::unnest()
  print(df_short)
}