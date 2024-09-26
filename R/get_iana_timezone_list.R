# Load libraries
renv::load()
library(xml2)
library(sf)
library(tidyverse)
library(tzdb)

# Time zones suck. The IANA list is far too long so lets use a shorter list Microsoft used a long time ago. 


#Import functions
walk(list.files(path = "R/fns",full.names = T),source)

#Create a lookup table of timezones in three categories: 
#iana_names - these are ones that are used by UNIX and other computer systems. There are >500 and many exist because there were different time zones in the past for different areas of the world. 
#current - these are time zones that are currently being used by a region of the world. 
#current significant - these are current, but where a region has a population <200k, it's instead mapped to the closest significant time zone. 

iana_names <- create_iana_old_and_cur_lookup_table(population_cut_off = 200000)
windows_iana_mapping <- create_windows_to_iana_mapping()


iana_with_windows <- iana_names %>% 
  left_join(windows_iana_mapping, by = "iana_name") %>% 
  left_join(windows_iana_mapping %>% rename_all(~paste0("current_",.x)), by = "current_iana_name") %>% 
  left_join(windows_iana_mapping %>% rename_all(~paste0("closest_sig_current_",.x)), by = "closest_sig_current_iana_name") %>% 
  dplyr::select("iana_name",                          
                "standard_abbr",
                "standard_utc_offset",
                "windows_id",
                "windows_name",
                "windows_display",
                "custom_label",
                "current_iana_name",
                "current_standard_abbr",
                "current_standard_utc_offset",
                "current_windows_id",
                "current_windows_name",
                "current_windows_display",
                "current_custom_label",
                "closest_sig_current_iana_name",
                "closest_sig_current_standard_abbr",
                "closest_sig_current_standard_utc_offset",
                "closest_sig_current_windows_id",
                "closest_sig_current_windows_name",
                "closest_sig_current_windows_display",
                "closest_sig_current_custom_label")

iana_with_windows %>% write_csv("output/iana_past_current_lookup_with_windows_names.csv")
