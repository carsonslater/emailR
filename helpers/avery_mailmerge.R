# Carson Slater ----------------------------------------------------------
#
# Date Created: 11.19.2025
# The `avery_mailmerge()` function creates a mail-merge-ready Excel file of the
# most recent address book. It begins by loading the latest address book from
# the `address_books` folder, then prepares the name fields so that household
# names are used when available, and individual first and last names are used
# otherwise. Address fields are renamed and organized to match standard Avery
# label formats. The function then saves the result as a dated Excel snapshot
# in the `avery` directory, producing a clean, consistently formatted file ready
# for use in Microsoft Word’s mail-merge workflow.
#
# ------------------------------------------------------------------------


avery_mailmerge <- function() {
  # Load latest address book
  latest_ab <- load_latest_ab(here::here("address_books"))

  xl <- latest_ab |>
    mutate(
      `First Name` = ifelse(is.na(household_name), first_name, household_name),
      `Last Name` = ifelse(is.na(household_name), last_name, "")
    ) |>
    rename(
      `Street Address` = street_address_line_1,
      `Street Address Line 2` = street_address_line_2,
      `City` = city,
      `State` = state,
      `Zip Code` = zip_code
    ) |>
    select(
      `First Name`,
      `Last Name`,
      `Street Address`,
      `Street Address Line 2`,
      `City`,
      `State`,
      `Zip Code`
    )

  snapshot_ts <- format(Sys.Date(), "%Y%m%d")
  snapshot_file <- here("avery", glue("{snapshot_ts}_address_book.xlsx"))
  writexl::write_xlsx(xl, snapshot_file)
}
