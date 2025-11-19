# Carson Slater ----------------------------------------------------------
#
# Date Created: 11.18.2025
# Description: This function loads the most recent timestamped address book CSV
# from a specified directory (default: current working directory). It searches for
# files matching the pattern "YYYYMMDD_address_book.csv", identifies the newest
# by date, and reads it into R as a tibble using readr::read_csv(). If no files
# are found, the function stops with an error.
#
# ------------------------------------------------------------------------

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
