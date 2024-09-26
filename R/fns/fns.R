  parse_utc_offset <- function(offset_str) {
    sign <- ifelse(substr(offset_str, 1, 1) == "+", 1, -1)
    hours <- as.numeric(substr(offset_str, 2, 3))
    minutes <- as.numeric(substr(offset_str, 4, 5))
    total_minutes <- sign * ((60*hours) +minutes)
    return(total_minutes)
  }

  
  #Create abbreviations for any list of time zones 
  
  create_abbreviations <- function(df){
  output <-df %>% 
    mutate(standard_abbr = purrr::map2_chr(date, iana_name, ~format(as.POSIXct(.x, tz = .y), format = "%Z")),
           order = if_else(str_detect(tolower(standard_abbr),"d"),2,1),
           standard_abbr =   case_when(standard_abbr %in% c("EST", "EDT") ~ "ET",  # Eastern Time
                                       standard_abbr %in% c("CST", "CDT") ~ "CT",  # Central Time
                                       standard_abbr %in% c("MST", "MDT") ~ "MT",  # Mountain Time
                                       standard_abbr %in% c("PST", "PDT") ~ "PT",  # Pacific Time
                                       TRUE ~ standard_abbr                  # Handle any other cases
           )) %>% 
    arrange(order) %>% 
    group_by(iana_name) %>% 
    filter(row_number() ==1) %>% 
    dplyr::select(iana_name,standard_abbr)  
  return(output)
  }
  
  create_custom_label <- function(df){
    output <-time_zones_full %>% 
      mutate(utc_sdt = paste0(substr(utc_offset,1,3),":",substr(utc_offset,4,5)),
             custom_label = paste0(utc_sdt," ",iana_name)) %>% 
      mutate(standard_abbr = purrr::map2_chr(date, iana_name, ~format(as.POSIXct(.x, tz = .y), format = "%Z")),
             order = if_else(str_detect(tolower(standard_abbr),"d"),2,1)) %>% 
      arrange(order) %>% 
      group_by(iana_name) %>% 
      filter(row_number() ==1) %>% 
      dplyr::select(iana_name,custom_label,standard_utc_offset = utc_offset)  
    return(output)
  }
  
  