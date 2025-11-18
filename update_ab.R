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

sheet_urls <- c(
  "https://docs.google.com/...",
)

# ---------------------------
# Parameters you should set
# ---------------------------
form_link <- "https://forms.gle/T7cqxk5iQiKk93tZ6"   # <-- put your Google Form / Sheet link here
from_email <- "carsonslater7@gmail.com"              # <-- sender address
smtp_creds_key <- "gmail"                            # <-- your blastula creds_key name (set up via create_smtp_creds_file or creds_key)
dry_run <- TRUE                                      # set FALSE to actually send

# ---------------------------
# Loading the latest address book
# ---------------------------
source(here("helpers", "load_latest_ab.R"))
source(here("helpers", "compose_update_email.R"))

# Your existing file
prior_ab <- load_latest_ab()

n_total <- nrow(prior_ab)
if (n_total == 0) stop("Address book is empty!")

# ---------------------------
# Preview the first email (always run so you can inspect)
# ---------------------------
preview_first <- compose_update_email(
  first_name = prior_ab$first_name[1],
  form_link = form_link
)
preview_first   # in RStudio / notebook this will show the preview

# ---------------------------
# Sending / Dry-run logic
# ---------------------------
# Build a send list with minimal required fields and safety filters
send_list <- ab_clean |>
  mutate(email_address = coalesce(email_address, email)) |> # just in case alternate column name
  filter(!is.na(email_address) & str_detect(email_address, "@")) |>
  mutate(
    first_name = if_else(!is.na(first_name) & first_name != "", first_name, "Friend"),
    sent_at = as.POSIXct(NA),
    status = NA_character_,
    note = NA_character_
  )

# Log file path
log_ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
log_file <- here::here(glue("send_log_{log_ts}.csv"))

# If dry run, don't call smtp_send; just simulate and write the log
if (dry_run) {
  message("DRY RUN mode ON — no emails will be sent. Set dry_run <- FALSE to actually send.")
  send_list <- send_list |>
    mutate(
      sent_at = Sys.time(),
      status = "DRY_RUN",
      note = "Preview/simulated send; no SMTP call"
    )
  readr::write_csv(send_list, log_file)
  message("Wrote dry-run log to: ", log_file)
} else {
  # Real send path (with error handling)
  creds <- creds_key(smtp_creds_key) # make sure this key exists and is configured
  results <- vector("list", nrow(send_list))

  for (i in seq_len(nrow(send_list))) {
    row <- send_list[i, ]
    to_addr <- row$email_address
    first <- row$first_name

    email_obj <- compose_update_email(first, form_link)

    # trySend to continue on error
    res <- tryCatch({
      smtp_send(
        email = email_obj,
        to = to_addr,
        from = from_email,
        subject = "Quick address update (only if you moved)",
        credentials = creds
      )
      list(status = "SENT", note = NA_character_)
    }, error = function(e) {
      list(status = "ERROR", note = as.character(e$message))
    })

    send_list$sent_at[i] <- Sys.time()
    send_list$status[i] <- res$status
    send_list$note[i] <- res$note

    message(glue("[{i}/{nrow(send_list)}] -> {to_addr} : {res$status}"))
  }

  readr::write_csv(send_list, log_file)
  message("Wrote send log to: ", log_file)
}

# ---------------------------
# Optional: save a fresh timestamped snapshot of the address book (if you want)
# ---------------------------
snapshot_ts <- format(Sys.Date(), "%Y%m%d")
snapshot_file <- here::here(glue("{snapshot_ts}_address_book.csv"))
readr::write_csv(ab_clean, snapshot_file)
message("Wrote snapshot: ", snapshot_file)
