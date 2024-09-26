# Load libraries
renv::load()
library(xml2)
library(tidyverse)
library(tzdb)

# Time zones suck. But we want to be a global website. 
# The IANA list is far too long so lets use a shorter list Microsoft used a long time ago. 

#Let's start by trying to group time zones together into the most populous similar time zone. 

population_by_time_zone <- read_csv("data/time_zones_with_population.csv") %>%
  rename(iana = tzid)
#Similar here is a time zone that has the same UTC+ at various points throughout the year. 
# Define the dates of interest
dates <- c("2023-01-01", "2023-03-31", "2023-07-01", "2023-11-25")

# Create functions to get UTC offset and abbreviation for a given time zone and date
get_utc_offset <- function(tz, date) {
  dt <- as.POSIXct(date, tz = tz)
  format(dt, format = "%z")
}

#We also want a nice UTC simplification for all these timezones, since the shortening timezone changes throughout the year. 
get_abbreviation <- function(tz, date) {
  dt <- as.POSIXct(date, tz = tz)
  format(dt, format = "%Z")
}

# Initialize a data frame with time zone names
timezone_data_raw <- data.frame(
  iana = tzdb_names(),
  stringsAsFactors = FALSE
)

# For each date, calculate the UTC offset and abbreviation for each time zone
for (date in dates) {
  # Sanitize date for column naming
  date_col <- gsub("-", "_", date)
  
  # Get UTC offset and abbreviation
  timezone_data_raw[[paste0("utc_", date_col)]] <- sapply(timezones, get_utc_offset, date = date)
  timezone_data_raw[[paste0("abbr_", date_col)]] <- sapply(timezones, get_abbreviation, date = date)
}

# Function to get the first abbreviation without "D" in it as the non daylight saving simplification of that timezone
get_first_standard_abbr <- function(row) {
  abbreviations <- c(row$abbr_2023_01_01, row$abbr_2023_03_31, row$abbr_2023_07_01, row$abbr_2023_11_25)
  first_standard <- abbreviations[!grepl("D", abbreviations)][1]
  if (is.na(first_standard)) {
    return(NA)
  } else {
    return(first_standard)
  }
}

# Process the data frame to include country and city
timezone_data <- timezone_data_raw  %>%    
  filter(!str_detect(iana,"Antarctica"),# Absurd time zones include Antarctica and the ocean where nobody lives. 
         !(iana %in% c("Etc/GMT+12","Etc/GMT-12"))) %>% 
  rowwise() %>%
  mutate(standard_abbr = get_first_standard_abbr(cur_data())) %>%
  mutate(standard_abbr =   case_when(standard_abbr %in% c("EST", "EDT") ~ "ET",  # Eastern Time
                                     standard_abbr %in% c("CST", "CDT") ~ "CT",  # Central Time
                                     standard_abbr %in% c("MST", "MDT") ~ "MT",  # Mountain Time
                                     standard_abbr %in% c("PST", "PDT") ~ "PT",  # Pacific Time
                                       TRUE ~ standard_abbr                  # Handle any other cases
    )) %>% 
  ungroup() %>%
  left_join(population_by_time_zone) %>% 
  arrange(desc(population)) %>% 
  group_by(utc_2023_01_01,utc_2023_03_31,utc_2023_07_01,utc_2023_11_25) %>% 
  mutate(iana_name = iana,
         iana_group = first(iana_name),
         iana_group_abbr = first(standard_abbr),
         iana_group_population = first(population)) %>% 
  ungroup() %>% 
  filter(iana_group_population>200000) %>% #Silly Australian 45 minute time zones can go. 
  dplyr::select(iana_name,
                standard_abbr,
                iana_group_abbr,
                iana_group) %>% 
  mutate(iana_group = if_else(iana_group == "Asia/Sakhalin","Asia/Magadan",iana_group)) # for this one the lower population is more recognisable

timezone_groups <- timezone_data %>% 
  group_by(iana_group,iana_group_abbr) %>% 
  summarise()




#Get windows to IANA join

# Define common zones
url <- "https://raw.githubusercontent.com/unicode-org/cldr/main/common/supplemental/windowsZones.xml"

# Read the XML file from the URL
xml_data <- read_xml(url)

# Extract all 'mapZone' nodes under 'windowsZones'
mapZone_nodes <- xml_find_all(xml_data, ".//mapZone")

# Extract attributes from each 'mapZone' node into a data frame
microsoft_iana_lookup <- data.frame(
  windows_name = xml_attr(mapZone_nodes, "other"),
  territory = xml_attr(mapZone_nodes, "territory"),
  iana_name = xml_attr(mapZone_nodes, "type"),
  stringsAsFactors = FALSE) %>% 
  mutate(iana_name = strsplit(iana_name, " ")) %>%
  unnest(iana_name) %>% 
  dplyr::select(-territory) %>% 
  distinct()



#List taken from 2013 Microsoft file - simpler list than IANA. 
#https://learn.microsoft.com/en-us/previous-versions/windows/embedded/gg154758(v=winembedded.80)?redirectedfrom=MSDN
microsoft_labels <- read_csv('data/top_timezones.csv') %>% 
  rename(windows_id = ID,
         windows_name = `Time zone name`,
         windows_display = `Display string`)
         
#These important time zones have been renamed recently... 
manual_zones <- tribble(~iana_name,~windows_name,~windows_display,
                        "Asia/Kathmandu","Nepal Standard Time","(UTC+05:45) Kathmandu",
                        "Asia/Kolkata","India Standard Time","(UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi",
                        "Asia/Yangon","Myanmar Standard Time","(UTC+06:30) Yangon (Rangoon)",
                        "Atlantic/Cape_Verde","Cabo Verde Standard Time","(UTC-01:00) Cabo Verde Is.")

microsoft_zones <- microsoft_labels%>% 
  inner_join(microsoft_iana_lookup, by = "windows_name") %>% 
  bind_rows(manual_zones)

all_zones <- timezone_data %>% left_join(microsoft_zones)

all_zone_groups <- timezone_groups %>% left_join(microsoft_zones %>% 
                                                         rename(iana_group = iana_name, 
                                                                windows_group_display = windows_display, 
                                                                windows_group_name = windows_name,
                                                                windows_group_id = windows_id)) 

all_zones_wide <- all_zones %>% 
  left_join(all_zone_groups) %>% 
  mutate(closest_windows_display = coalesce(windows_display,windows_group_display))

all_zones_wide %>% write_csv("output/IANA_windows_lookup.csv")
