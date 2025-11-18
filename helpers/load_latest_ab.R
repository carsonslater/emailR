load_latest_ab <- function(path = ".") {

  files <- list.files(path, pattern = "^[0-9]{8}_address_book\\.csv$", full.names = TRUE)

  if (length(files) == 0) {
    stop("No timestamped address book files found in the directory.")
  }

  # Extract the YYYYMMDD prefix
  dates <- files %>%
    basename() %>%
    str_extract("^[0-9]{8}") %>%
    lubridate::ymd()

  # Pick newest file
  newest_file <- files[which.max(dates)]

  message("Loading: ", newest_file)

  readr::read_csv(newest_file)
}
