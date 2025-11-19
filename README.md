# emailR

> Address Book Update Automation

This project automates the workflow of collecting Google Form responses, maintaining an up-to-date address book, and sending personalized update emails using **R** and **blastula**.

---

## **Project Structure**

```

├── helpers
│   ├── compose_update_email.R   # Function to generate personalized HTML emails
│   ├── load_latest_ab.R         # Function to load the most recent address book CSV
│   └── test_send.R              # Function to send a test email to verify SMTP setup
├── update_ab.R                  # Main script: merges new responses and optionally sends emails
└── utils                        # Utility files
└── sheet_link.txt           # Stores the URL to your Google Sheet responses

````

---

## **Workflow Overview**

1. **Import latest Google Form responses**
   `update_ab.R` reads the URL from `utils/sheet_link.txt` and imports new responses via `googlesheets4`.

2. **Merge with existing address book**
   The script uses `load_latest_ab()` to load the most recent snapshot and combines it with new responses, keeping only the most recent entry per email address.

3. **Preview and compose emails**
   `compose_update_email()` generates a personalized HTML email for each recipient. A preview of the first email is always displayed before sending.

4. **Send emails**
   - Run in **dry-run mode** by default (`dry_run = TRUE`) to simulate sending and create a log.
   - Switch to live mode (`dry_run = FALSE`) to actually send emails using blastula and stored SMTP credentials.
   - Each send is logged with status and timestamp.

5. **Save snapshots and logs**
   - A timestamped snapshot of the updated address book is saved.
   - A timestamped send log records all simulated or actual email sends.

6. **Test email functionality**
   `test_send()` allows sending a single test email to verify SMTP credentials and blastula setup.

---

## **Setup Instructions**

1. **Install required packages**

```r
install.packages(c(
  "tidyverse", "lubridate", "googlesheets4", "janitor",
  "blastula", "glue", "here"
))
````

2. **Google Sheets**

   - Save the URL of your form responses in `utils/sheet_link.txt`.

3. **Blastula credentials**

   - Create a credentials key (e.g., `gmail_creds`) or use environment variables for SMTP_PASSWORD.
   - See `test_send.R` for an example of verifying the setup.

4. **Configure main script** (`update_ab.R`)
   Set the following parameters at the top of the file:

   ```r
   form_link <- "YOUR_GOOGLE_FORM_LINK"
   from_email <- "YOUR_EMAIL_ADDRESS"
   smtp_creds_key <- "YOUR_CREDS_KEY"
   dry_run <- TRUE   # Set FALSE to actually send
   ```

5. **Run the workflow**

   ```r
   source("update_ab.R")
   ```

---

## **Notes & Best Practices**

- Always start with `dry_run = TRUE` to ensure email formatting and recipient list are correct.
- Each run produces timestamped logs and snapshots for reproducibility.
- Ensure your address book and Google Form responses maintain consistent column names.
- First names missing from responses are replaced with `"Friend"` for personalization.

---

## **Author**

Carson Slater
Date Created: 11.18.2025
