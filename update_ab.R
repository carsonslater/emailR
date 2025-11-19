# Carson Slater ----------------------------------------------------------
#
# Date Created: 11.18.2025
# Description: This script pulls the latest Google Form responses, merges them
# with the existing address book, previews a personalized update email, and
# optionally sends it to each contact using blastula. It reads the Google
# Sheet URL from utils/sheet_link.txt, imports new responses, and combines
# them with the most recent address book snapshot, keeping only the latest
# entry per email address. The first email is previewed via compose_update_email(),
# and a validated send list is built with proper email addresses, default
# first names, and logging fields. The script can run in dry-run mode (default,
# no emails sent) or live mode using stored SMTP credentials, and it writes a
# timestamped send log and saves a new snapshot of the updated address book.
# Before running, set form_link, from_email, smtp_creds_key, and dry_run.
#
# ------------------------------------------------------------------------


library("tidyverse")
library("lubridate")
library("googlesheets4")
library("janitor")
library("blastula")
library("glue")
library("here")

# ----------------------------------------------------------
# 1. Pull new Google Sheet responses
# ----------------------------------------------------------

sheet_url <- readLines(here::here("utils", "sheet_link.txt"), warn = FALSE)

current_sheet <- read_sheet(sheet_url) |>
  janitor::clean_names() |>
  mutate(zip_code = map(zip_code, as.character)) |>
  unnest(zip_code, keep_empty = TRUE) |>
  relocate(timestamp, .after = zip_code) |>
  rename(last_updated = timestamp) |>
  rename(household_name = household_name_if_applicable_e_g_smith_family) |>
  rename(state = state_two_letter_abbreviations_please) |>
  relocate(email_address, .after = last_name)

# ---------------------------
# Parameters you should set
# ---------------------------
form_link <- "https://forms.gle/T7cqxk5iQiKk93tZ6"   # <-- put your Google Form / Sheet link here
from_email <- "carsonslater7@gmail.com"              # <-- sender address
smtp_creds_key <- "gmail_creds"                      # <-- your blastula creds_key name (set up via create_smtp_creds_file or creds_key)
dry_run <- TRUE                                      # set FALSE to actually send

# ---------------------------
# Loading the most recent address book
# ---------------------------
source(here("helpers", "load_latest_ab.R"))
source(here("helpers", "compose_update_email.R"))

# Your existing file
prior_ab <- load_latest_ab(here::here("address_books")) |>
  mutate(across(c(
    first_name,
    last_name,
    street_address_line_1,
    street_address_line_2,
    city
  ),
  tools::toTitleCase))

n_total <- nrow(prior_ab)
if (n_total == 0) stop("Address book is empty!")

# ---------------------------
# Compile into the current address book
# ---------------------------
current_ab <- bind_rows(prior_ab, current_sheet) |>
  group_by(email_address) |>
  slice_max(order_by = last_updated, n = 1, with_ties = FALSE) |>
  ungroup() |>
  separate_wider_delim(
    street_address_line_1,
    delim = ",",
    names = c("temp_line1", "temp_line2"),
    too_few = "align_start"
  ) |>
  mutate(
    extracted_line2 = str_extract(temp_line1, "(?i)(apt|unit|suite| ste|attn| msc|#)\\s*\\S+.*$"),
    temp_line1 = str_trim(str_remove(temp_line1, "(?i)(apt|unit|suite| ste|attn| msc|#)\\s*\\S+.*$"))
  ) |>
  mutate(
    street_address_line_2 = coalesce(
      street_address_line_2,
      temp_line2,
      extracted_line2
    ),
    street_address_line_1 = temp_line1
  ) |>
  select(-temp_line1, -temp_line2, -extracted_line2) |>
  mutate(
    street_address_line_1 = str_trim(street_address_line_1),
    street_address_line_2 = str_trim(street_address_line_2)
  ) |>
  relocate(street_address_line_1, .before = street_address_line_2) |>
  relocate(household_name, .after = last_name)

# Cleaning
name_to_abb <- setNames(state.abb, toupper(state.name))

# Common misspellings → correct abbreviations
fixes <- c(
  "GEORIGA"    = "GA",
  "TENNESSSEE" = "TN",
  "ILLINOID"   = "IL",
  "CALIFORNIA" = "CA",
  "COLORADO"   = "CO",   # fixes capitalization of full names
  "ARIZONA"    = "AZ"    # if inconsistent
)

current_ab <- current_ab |>
  mutate(
    # Step 1: trim + uppercase
    state = state |>
      str_trim() |>
      str_to_upper(),

    # Step 2: convert full names → abbreviations
    state = ifelse(
      state %in% names(name_to_abb),
      name_to_abb[state],
      state
    ),

    # Step 3: fix common typos / alternate spellings
    state = recode(state, !!!fixes),

    # Step 4: replace anything invalid with NA
    state = ifelse(state %in% state.abb, state, NA)
  )

# ---------------------------
# Preview the first email (always run so you can inspect)
# ---------------------------
preview_first <- compose_update_email(
  first_name = current_ab$first_name[1],
  form_link = form_link
)
preview_first   # in RStudio / notebook this will show the preview

# ---------------------------
# Sending / Dry-run logic
# ---------------------------
# Build a send list with minimal required fields and safety filters
send_list <- current_ab |>
  filter(!is.na(email_address) & str_detect(email_address, "@")) |>
  mutate(
    first_name = if_else(!is.na(first_name) & first_name != "", first_name, "Friend"),
    sent_at = as.POSIXct(NA),
    status = NA_character_,
    note = NA_character_
  ) |>
  mutate(first_name = str_to_title(first_name))

# Logging path
log_ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
log_file <- here("send_logs", glue("send_log_{log_ts}.csv"))

# ----------------------------------------------------------
# 4. Dry-run / Real send
# ----------------------------------------------------------

if (dry_run) {

  message("DRY RUN — no emails will be sent.")
  send_list <- send_list |>
    mutate(
      sent_at = Sys.time(),
      status = "DRY_RUN",
      note = "Simulated send"
    )

  readr::write_csv(send_list, log_file)
  message("Wrote dry-run log to: ", log_file)

} else {

  # Load encrypted Gmail credentials
  creds <- creds_file(smtp_cred_file)

  for (i in seq_len(nrow(send_list))) {

    row <- send_list[i, ]
    to_addr <- row$email_address
    first <- row$first_name

    email_obj <- compose_update_email(first, form_link)

    res <- tryCatch({
      smtp_send(
        email = email_obj,
        to = to_addr,
        from = from_email,
        subject = "Want a Christmas Card? (Address update - only if you moved)",
        credentials = creds_envvar(
          user = "carsonslater7@gmail.com",
          pass_envvar = "SMTP_PASSWORD",
          provider = "gmail"
        )
      )
      list(status = "SENT", note = NA_character_)
    }, error = function(e) {
      list(status = "ERROR", note = as.character(e$message))
    })

    send_list$sent_at[i] <- Sys.time()
    send_list$status[i] <- res$status
    send_list$note[i] <- res$note

    message(glue("[{i}/{nrow(send_list)}] -> {to_addr}: {res$status}"))
  }

  readr::write_csv(send_list, log_file)
  message("Wrote send log to: ", log_file)
}

# ----------------------------------------------------------
# 5. Save snapshot of updated address book
# ----------------------------------------------------------
snapshot_ts <- format(Sys.Date(), "%Y%m%d")
snapshot_file <- here("address_books", glue("{snapshot_ts}_address_book.csv"))
readr::write_csv(current_ab, snapshot_file)

message("Wrote snapshot: ", snapshot_file)


# Test Email -------------------------------------------------------------

source(here::here("helpers", "test_send.R"))
test_send()
