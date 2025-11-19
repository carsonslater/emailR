# Carson Slater ----------------------------------------------------------
#
# Date Created: 11.18.2025
# Description: This function generates a personalized HTML email using blastula.
# It accepts a recipient's first name and a Google Form link, providing a fallback
# of "Friend" if the name is missing. The email reminds the recipient to update
# their mailing address if they have moved recently, and uses the from_name
# parameter (default: "The Slaters") for the sender's signature. The body is
# composed in Markdown via glue for dynamic text insertion.
#
# ------------------------------------------------------------------------


compose_update_email <- function(first_name, form_link, from_name = "The Slaters") {
  # fallback for missing name
  if (is.na(first_name) || trimws(first_name) == "") first_name <- "Friend"
  compose_email(
    body = md(glue("
Howdy {first_name},

The Slater family is updating our address book and we want to make sure we have the correct mailing address on file, in case we need to send you fun things like Christmas cards, letters, etc.

If **you have moved within the last year**, would you please take a moment to update your information here?

👉 **Update your address (only if you moved):** [{form_link}]({form_link})

If you haven't moved recently, no action is needed — thanks!

Best,

{from_name}

---
*Concerned this is a scam? It isn't! But feel free to text/call Carson at [+1 (480) 320-8898](tel:4803208898) to confirm.*
    "))
  )
}
