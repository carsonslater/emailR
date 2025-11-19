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


compose_update_email <- function(
  first_name,
  line1,
  line2,
  city,
  state,
  zip,
  form_link,
  from_name = "The Slaters"
) {
  # fallback for missing name
  if (is.na(first_name) || trimws(first_name) == "") first_name <- "Friend"

  # Handle NA values in address fields
  line1 <- if (is.na(line1) || trimws(line1) == "") "" else line1
  line2 <- if (is.na(line2) || trimws(line2) == "") "" else line2
  city <- if (is.na(city) || trimws(city) == "") "" else city
  state <- if (is.na(state) || trimws(state) == "") "" else state
  zip <- if (is.na(zip) || trimws(zip) == "") "" else zip

  # Build address lines conditionally
  address_line1 <- if (line1 != "") paste0(line1, "\n\n") else ""
  address_line2 <- if (line2 != "") paste0(line2, "\n\n") else ""

  # Build city/state/zip line
  city_state_zip_parts <- c(city, state, zip)
  city_state_zip_parts <- city_state_zip_parts[city_state_zip_parts != ""]

  if (length(city_state_zip_parts) > 0) {
    # Format as "City, ST Zip" or whatever parts are available
    if (city != "" && state != "" && zip != "") {
      city_state_zip <- paste0(city, ", ", state, " ", zip)
    } else if (city != "" && state != "") {
      city_state_zip <- paste0(city, ", ", state)
    } else {
      city_state_zip <- paste(city_state_zip_parts, collapse = " ")
    }
  } else {
    city_state_zip <- ""
  }

  compose_email(
    body = md(glue("
Howdy {first_name},

The Slater family is updating our address book and we want to make sure we have the correct mailing address on file, in case we need to send you fun things like Christmas cards, letters, etc.

If **you have moved within the last year**, would you please take a moment to update your information here?

The current address we have for you is:

{address_line1}{address_line2}{city_state_zip}

👉 **Update your address (only if you moved):** [{form_link}]({form_link})

If you haven't moved recently, or the address listed is correct, then no action is needed – thanks!

Best,

{from_name}

---
*Concerned this is a scam? It isn't! But feel free to text/call Carson at [+1 (480) 320-8898](tel:4803208898) to confirm.*
    "))
  )
}
