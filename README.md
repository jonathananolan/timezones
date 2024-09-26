There are ~600 IANA time zones, many are not meaningfuly distinct for current and future dates. [Time-zone boundary builder](https://github.com/evansiroky/timezone-boundary-builder) maintains an up to date map of the ~70 time zones that are mapped to a current geographical area. 

But most computers in the world use [IANA names](https://github.com/eggert/tz), and for many computers the IANA name is one of more than 600 locations that represent historical differences in time zones across different regions. 

When creating user interfaces that deal only with the future, it would be handy to be able to map the full ~600 list to the much shorter 70 list so that it's easier for users to pick their time zone in a drop-down. 

[Download This CSV file](https://github.com/jonathananolan/timezones/raw/refs/heads/main/output/iana_past_current_lookup_with_windows_names.csv) to access a mapping of:
* All ~600 IANA time zones to the 62 'current' iana time zones,
* All ~600 IANA time zones to the geographically closest time zone from a list of 48 'significant current' time zones where there are more than 200,000 people living. Closest signfiicant time zones match current time zone for 99.998% of the world's population. 

For each of the classes provided (iana_name, current_iana_name, and closest_sig_current), the following columns are available
* iana_name - the name of the city used to denote an area in the iana database
* standard_abbr - The abbreviation used in this time zone when there is no daylight savings in effect
* standard_utc_offset - the UTC offset in this time zone when there is no daylight savings in effect
* windows_id - an id used in older versions of windows for this time zone
* windows_name - the name used for this time zone in older versions of windows
* windows_display - the display used for this time zone in older versions of windows
* custom_label - a custom label for this time zone created from the standard_utc_offset and iana_name
  
Windows and custom labels are useful because they are ordered by UTC offset, and frequent travellers have an innate senese of where their time zone is on a list ordered by UTC offset. 

All mappings of iana time zones to current iana time zones are accurate as of September 26 2024 - but should be updated by the user as [Time-zone boundary builder](https://github.com/evansiroky/timezone-boundary-builder) updates. 
