# Carson Slater ----------------------------------------------------------
#
# Date Created: 11.18.2025
# Description: This function sends a test email using blastula to verify Gmail
# SMTP setup. It composes a sample update email via compose_update_email(),
# using default parameters for recipient, sender, and Google Form link. The
# function attempts to send the email with credentials from the environment
# variable SMTP_PASSWORD and reports success or any error messages. Useful for
# confirming that the email sending workflow is correctly configured before
# running live campaigns.
#
# ------------------------------------------------------------------------

test_send <- function(
  to = "carsonslater7@gmail.com",
  from = "carsonslater7@gmail.com",
  cred_file = "gmail_creds",
  first_name = "Carson",
  line1 = "123 Main Street",
  line2 = "Apt 4B",
  city = "Austin",
  state = "TX",
  zip = "78701",
  form_link = "https://forms.gle/T7cqxk5iQiKk93tZ6"
) {
  library(blastula)

  message("Composing test email...")
  email_obj <- compose_update_email(
    first_name = first_name,
    line1 = line1,
    line2 = line2,
    city = city,
    state = state,
    zip = zip,
    form_link = form_link
  )

  message("Sending test email to: ", to)
  tryCatch({
    smtp_send(
      email = email_obj,
      from = from,
      to = to,
      subject = "Test — blastula Gmail setup",
      credentials = creds_envvar(
          user = "carsonslater7@gmail.com",
          pass_envvar = "SMTP_PASSWORD",
          provider = "gmail"
        )
    )
    message("✓ SUCCESS: Test email sent.")
  }, error = function(e) {
    message("✗ ERROR: ", e$message)
  })
}
