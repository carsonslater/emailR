library("googlesheets4")
library("tidyverse") # For downstream processing
library("lubridate")
library("here")
library("glue")

# gs4_auth(scopes = "https://www.googleapis.com/auth/spreadsheets", cache = FALSE)

# You can use the full URL or just the Sheet ID
sheet_urls <- c(
  "https://docs.google.com/spreadsheets/d/1m87GfJchPV1dh_sMAmikHrmEOQb5745fx2i7Otbdkss/edit?resourcekey=&gid=701274371#gid=701274371",
  "https://docs.google.com/spreadsheets/d/13rqwlfjiy0LtEfqieXbevqkn85LdclIGCPeuC-YGa3A/edit?resourcekey=&gid=1355956526#gid=1355956526"
)

# Read the data
dfs <- map(sheet_urls, ~ read_sheet(.x) |> janitor::clean_names())

# Verify the import
map(dfs, ~ glimpse(.x))

old_address_book <- dfs[[1]] |>
  select(-c(
    "do_you_currently_reside_in_the_usa",
    "what_is_your_address",
    "what_city_do_you_live_in",
    "what_country_do_you_live_in",
    "would_you_like_a_christmas_card_or_other_mailed_updates_from_carson_slater_mailed_to_you_indefinitely"
  )) |>
  rename(
    update1 = would_you_like_a_christmas_card_or_other_updates_from_carson_slater_mailed_to_you_indefinitely,
    street_address = street_address_and_apt_unit_number_if_applicable
  ) |>
  filter(update1 == "Yes") |>
  mutate(zip_code = as.character(zip_code))

wedding_address_book <- dfs[[2]] |>
  select(-will_you) |>
  mutate(zip_code = map(zip_code, as.character)) |>
  unnest(zip_code, keep_empty = TRUE) |>
  rename(
    first_name = first_name_of_you_and_then_of_your_significant_other_if_applicable,
    last_name = last_name_of_you_and_then_of_your_significant_other_if_applicable,
    street_address = street_address_and_apt_unit_number_if_applicable
  ) |>
  drop_na()

# rm(dfs)

my_by <- join_by(email_address, street_address, city, state, zip_code)
ab <- full_join(old_address_book, wedding_address_book, by = my_by)


ab_clean <- ab |>
  mutate(
    # 1. Coalesce names: Take .x, if NA take .y
    first_name = coalesce(first_name.x, first_name.y),
    last_name  = coalesce(last_name.x, last_name.y),

    # 2. Determine the most recent interaction per row
    # pmax compares the two columns row-wise and ignores NAs
    latest_interaction = pmax(timestamp, sa, na.rm = TRUE)
  ) |>
  # 3. Filter for the most recent entry per person
  group_by(first_name, last_name) |>
  arrange(desc(latest_interaction)) |>
  slice_head(n = 1) |>
  ungroup() |>
  # 4. Clean up the dataset
  select(
    first_name,
    last_name,
    email_address,
    street_address,
    city,
    state,
    zip_code,
    last_updated = latest_interaction
  )

# Verify the output
glimpse(ab_clean)

ts <- format(Sys.Date(), "%Y%m%d")
outfile <- here::here(glue("{ts}_address_book.csv"))
write_csv(ab_clean, outfile)
