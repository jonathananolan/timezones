# Load libraries
renv::load()
library(xml2)
library(tidyverse)
# Time zones suck. But we want to be a global website. 
# The IANA list is far too long so lets use a shorter list Microsoft used a long time ago. 

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
  mutate(abbreviation = sapply(iana_name, function(tz) format(with_tz(Sys.time(), tzone = tz), "%Z")))

short_list %>% write_csv("list_of_feather_timezones.csv")
