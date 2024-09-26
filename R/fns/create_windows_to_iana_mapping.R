# Load libraries
library(sf)
library(raster)
library(exactextractr)
library(tidyverse)
create_windows_to_iana_mapping <- function() {
  
  
  
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
                          "Atlantic/Cape_Verde","Cabo Verde Standard Time","(UTC-01:00) Cabo Verde Is.",
                          "Asia/Sakhalin","Vladivostok Standard Time","(UTC+11:00) Vladivostok",
                          "Asia/Gaza","Jerusalem Standard Time","(UTC+02:00) Jerusalem Standard Time") 
  microsoft_zones <- microsoft_labels%>% 
    inner_join(microsoft_iana_lookup, by = "windows_name") %>% 
    bind_rows(manual_zones)
  
  return(microsoft_zones)}
