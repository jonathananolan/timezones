population_by_timezone

time_zone_files <- download.file("https://github.com/evansiroky/timezone-boundary-builder/releases/download/2024b/timezones-now.shapefile.zip",destfile = "data/from_net/time_zone_map.zip")
unzip(zipfile = "data/from_net/time_zone_map.zip",exdir = "data/from_net/")


options(timeout=1000)

download.file("https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2025_GLOBE_R2023A_54009_1000/V1-0/GHS_POP_E2025_GLOBE_R2023A_54009_1000_V1_0.zip",
              destfile = "data/from_net/ghsl_1km_pop.zip")

unzip(zipfile = "data/from_net/ghsl_1km_pop.zip",exdir = "data/from_net/")


# Load libraries
library(sf)
library(raster)
library(exactextractr)

# Step 1: Read time zones shapefile
time_zone_map <- st_read("data/from_net/combined-shapefile-now.shp")

# Step 2: Read population raster
pop <- raster("data/from_net/GHS_POP_E2025_GLOBE_R2023A_54009_1000_V1_0.tif")

# Step 3: Reproject time zones to match raster CRS
tz_mollweide <- st_transform(time_zone_map, crs = crs(pop))

# Step 4: Calculate population sum within each time zone
tz_mollweide$population <- exact_extract(pop, tz_mollweide, 'sum')

tz_mollweide %>% st_drop_geometry() %>% write_csv("data/time_zones_with_population.csv")