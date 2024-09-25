# Load libraries
renv::load()
library(xml2)
library(tidyverse)
# Time zones suck. But we want to be a global website. 
# The IANA list is far too long so lets use a shorter list Microsoft used a long time ago. 


# Get all the IANA time zones
timezones <- OlsonNames()

# Create a function to extract the abbreviation for each timezone
get_abbreviation <- function(tz) {
  format(Sys.time(), tz = tz, format = "%Z")
}

# Create a data frame with time zones and their abbreviations
all_iana_names <- data.frame(
  iana_name = timezones,
  abbreviation = sapply(timezones, get_abbreviation),
  stringsAsFactors = FALSE,
  row.names = NULL
)

important_time_zones <- c("America/Montreal",
                          "America/Nassau",
                          "America/Toronto",
                          "Canada/Eastern",
                          "US/Eastern",
                          "US/Michigan",
                          "America/Louisville",
                          "America/Detroit",
                          "America/Indianapolis",
                          "America/Chicago",
                          "America/Winnipeg",
                          "US/Central",
                          "Canada/Central",
                          "America/Havana",
                          "Canada/Pacific",
                          "America/Los_Angeles",
                          "America/Vancouver",
                          "US/Pacific",
                          "America/Los_Angeles",
                          "America/New_York")

north_american_time_zones <- all_iana_names %>% 
  filter(iana_name %in% important_time_zones) %>% 
  mutate(feather_display_string = iana_name)




# Define the URL to the raw XML file
url <- "https://raw.githubusercontent.com/unicode-org/cldr/main/common/supplemental/windowsZones.xml"

# Read the XML file from the URL
xml_data <- read_xml(url)

# Extract all 'mapZone' nodes under 'windowsZones'
mapZone_nodes <- xml_find_all(xml_data, ".//mapZone")

# Extract attributes from each 'mapZone' node into a data frame
windows_tz <- data.frame(
  windows = xml_attr(mapZone_nodes, "other"),
  #territory = xml_attr(mapZone_nodes, "territory"),
  iana = xml_attr(mapZone_nodes, "type"),
  stringsAsFactors = FALSE
) %>% 
  distinct(windows, .keep_all = T)

#List taken from 2013 Microsoft file - simpler list than IANA. 
#https://learn.microsoft.com/en-us/previous-versions/windows/embedded/gg154758(v=winembedded.80)?redirectedfrom=MSDN
display_short_list <- read_csv('data/top_timezones.csv')


short_list <- display_short_list %>% 
  inner_join(windows_tz, by = c("Time zone name" = "windows")) %>% 
  rename(microsoft_id = ID,
         microsoft_display = `Time zone name`,
         feather_display_string = `Display string`,
         iana_name = iana) %>% 
  filter(!str_detect(iana_name,"Etc/")) %>% 
  mutate(abbreviation = sapply(iana_name, function(tz) format(with_tz(Sys.time(), tzone = tz), "%Z"))) %>% 
  bind_rows(north_american_time_zones) %>% 
  distinct(iana_name, .keep_all = T)

short_list %>% write_csv("list_of_feather_timezones.csv")
