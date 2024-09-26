# Load libraries
library(sf)
library(raster)
library(exactextractr)
library(tidyverse)
create_iana_old_and_cur_lookup_table <- function(population_cut_off = 200000) {
  
# The time timezone-boundary-builder shape file contains a list of all cur timezones that are in the world. 
# Let's link that short list to the much longer list of historical time zones
  
time_zone_file <- "data/from_net/time_zone_map.zip"
time_zone_url <- "https://github.com/evansiroky/timezone-boundary-builder/releases/download/2024b/timezones-now.shapefile.zip"
print(paste("Pulling list of cur timezones from",time_zone_url,". Check that this is up to date"))
if(!file.exists(time_zone_file)){
  time_zone_files <- download.file(time_zone_url,destfile = "data/from_net/time_zone_map.zip")
  unzip(zipfile = time_zone_file,exdir = "data/from_net/")
}


if(!file.exists("data/from_net/ghsl_1km_pop.zip")){
options(timeout=1000)

download.file("https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2025_GLOBE_R2023A_54009_1000/V1-0/GHS_POP_E2025_GLOBE_R2023A_54009_1000_V1_0.zip",
              destfile = "data/from_net/ghsl_1km_pop.zip")

unzip(zipfile = "data/from_net/ghsl_1km_pop.zip",exdir = "data/from_net/")
}

# Step 1: Read time zones shapefile
time_zone_map <- st_read("data/from_net/combined-shapefile-now.shp")

# Step 2: Read population raster
pop <- raster("data/from_net/GHS_POP_E2025_GLOBE_R2023A_54009_1000_V1_0.tif")

# Step 3: Reproject time zones to match raster CRS
tz_mollweide_sf <- st_transform(time_zone_map, crs = crs(pop))

# Step 4: Calculate population sum within each time zone
tz_mollweide_sf$population <- exact_extract(pop, tz_mollweide_sf, 'sum') 


# For time zones less than the cuttoff of low population, let's use a nearby timezone as the 'significant' nearby time zone. 
tz_mollweide <- tz_mollweide_sf%>% st_centroid()

high_pop_areas <- tz_mollweide %>% filter(population>population_cut_off)
low_pop_areas  <- tz_mollweide %>% filter(population<=population_cut_off)

# Find the nearest high population area for each low population area
low_pop_areas <- low_pop_areas %>%
  mutate(
    nearest_high_pop_tzid = high_pop_areas$tzid[
      st_nearest_feature(geometry, high_pop_areas)
    ]
  )

time_zones_cur <- high_pop_areas %>% 
                      bind_rows(low_pop_areas) %>% 
                      mutate(iana_name = tzid,
                             closest_sig_current_iana_name = coalesce(nearest_high_pop_tzid,tzid)) %>% 
  st_drop_geometry() %>% 
  dplyr::select(iana_name,
                closest_sig_current_iana_name,
                population)
  

#Now for each of the long list of 500 timezones, we want to see which they match to. 
#To facilitate this, we check every month for the next couple of years and match old time zones to new ones based on times always matching. 

cur_time <- Sys.time()

#For each month in the next 2 years, find the UTC offset (time relative to UTC) 
find_utc_for_sample_dates <- function(df){
  output <- df  %>%
    expand_grid(tibble(date = seq.POSIXt(cur_time,cur_time+years(2),by = "month"))) %>% 
    mutate(utc_offset = purrr::map2_chr(date, iana_name, ~format(as.POSIXct(.x, tz = .y), format = "%z"))) 
  return(output)
}

#Do this for our list of 'cur' time zones
time_zones_cur_dates <- time_zones_cur %>% 
  find_utc_for_sample_dates() %>% 
  rename(current_iana_name = iana_name) 

time_zones_cur_wide <- time_zones_cur_dates %>% 
  pivot_wider(names_from = date,
              values_from = utc_offset) 

#Do this for the fuller list of time zones
time_zones_full <- tibble(iana_name = OlsonNames()) %>% 
  find_utc_for_sample_dates()

time_zones_full_wide <- time_zones_full %>% 
  pivot_wider(names_from = date,
              values_from = utc_offset) 



#Now join the full dataset with the 'cur' time zones based on the same utc offset for each date. 
#Then add abbreviations for the non daylight savings abbreviation of that time zone

all_time_zones_with_name_and_cur <- time_zones_full_wide %>% 
  left_join(time_zones_cur_wide,
            relationship = "many-to-many") %>% 
  arrange(desc(population)) %>% 
  group_by(iana_name) %>% 
  filter(row_number() == 1) %>%
  dplyr::select(iana_name,
                current_iana_name,
                closest_sig_current_iana_name) %>% 
  left_join(create_abbreviations(time_zones_full), by = join_by(iana_name)) %>% 
  left_join(create_abbreviations(time_zones_full) %>% rename_all(~paste0("current_",.x)), by = "current_iana_name")  %>%
  left_join(create_abbreviations(time_zones_full) %>% rename_all(~paste0("closest_sig_current_",.x)), by = "closest_sig_current_iana_name") %>% 
  left_join(create_custom_label(time_zones_full), by = join_by(iana_name)) %>% 
  left_join(create_custom_label(time_zones_full) %>% rename_all(~paste0("current_",.x)), by = "current_iana_name")  %>%
  left_join(create_custom_label(time_zones_full) %>% rename_all(~paste0("closest_sig_current_",.x)), by = "closest_sig_current_iana_name") %>% 
  dplyr::select(order(colnames(.)))

  


return(all_time_zones_with_name_and_cur)

}

