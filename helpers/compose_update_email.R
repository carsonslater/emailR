compose_update_email <- function(first_name, form_link, from_name = "The Slaters") {
  # fallback for missing name
  if (is.na(first_name) || trimws(first_name) == "") first_name <- "Friend"
  compose_email(
    body = md(glue("
Howdy {first_name},

I'm updating my address book and want to make sure I have the correct mailing address on file, in case I need to send you fun things like Christmas cards, letters, etc.

If **you have moved within the last year**, would you please take a moment to update your information here?

👉 **Update your address (only if you moved):** [{form_link}]({form_link})

If you haven't moved recently, no action is needed — thanks!

Best,
{from_name}
    "))
  )
}
