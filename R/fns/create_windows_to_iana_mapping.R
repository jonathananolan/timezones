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
  
  
  
  #List taken from Microsoft windows 11 and 2013
 #https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones?view=windows-11  
 #  #https://learn.microsoft.com/en-us/previous-versions/windows/embedded/gg154758(v=winembedded.80)?redirectedfrom=MSDN

  microsoft_labels_windows11 <- read_csv('data/microsoft_time_zones_windows_11.csv') %>% 
    mutate(windows_display = paste(UTC,`Timezone description`)) %>% 
    select(windows_name = Timezone,
           windows_display) %>% 
    distinct()
  
  
  microsoft_labels_2013 <- read_csv('data/microsoft_timezones_2013.csv') %>% 
    select(windows_name = `Time zone name`,
           windows_display = `Display string`) %>% 
    distinct()
  
  microsoft_labels_azure <- read_csv('data/microsoft_timezones_azure.csv') %>% 
    select(windows_name = `Time zone ID`,
           windows_display = `Time zone display name` ) %>% 
    distinct()
  
  
  microsoft_labels <- microsoft_labels_windows11 %>% 
    bind_rows(microsoft_labels_2013) %>% 
    bind_rows(microsoft_labels_azure) %>% 
    distinct(windows_name,.keep_all = T)
  
  
  
  #These time zones have been renamed recently or removed from the mapping file... 
  manual_zones <- tribble(~iana_name,~windows_name,~windows_display,
                          "Asia/Kolkata","India Standard Time","(UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi",
                          "Asia/Yangon","Myanmar Standard Time","(UTC+06:30) Yangon (Rangoon)",
                          "Asia/Sakhalin","Vladivostok Standard Time","(UTC+11:00) Vladivostok",
                          "Asia/Gaza","Jerusalem Standard Time","(UTC+02:00) Jerusalem Standard Time",
                          "America/Whitehorse","Yukon Standard Time","(UTC-07:00) Yukon",
                          "America/Dawson","Yukon Standard Time","(UTC-07:00) Yukon",
                          "Africa/Juba","South Sudan Standard Time","(UTC+2:00) Juba",
                          "Asia/Qyzylorda","Qyzylorda Standard Time","(UTC+05:00) Qyzylorda",
                          "Asia/Kathmandu","Nepal Standard Time","(UTC+05:45) Kathmandu",
                          "America/Nuuk","Greenland Standard Time","(UTC-03:00) Greenland") 
  
  

  
  
  microsoft_zones <- microsoft_labels%>% 
    distinct() %>% 
    right_join(microsoft_iana_lookup, by = "windows_name") %>% 
    bind_rows(manual_zones) %>% 
    arrange(windows_display) %>% 
    distinct(iana_name, .keep_all = T)
  
  return(microsoft_zones)}
