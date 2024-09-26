There are over 500 IANA timezones, but not many are meaningfuly distinct for current and future dates. [Time-zone boundary builder](https://github.com/evansiroky/timezone-boundary-builder) maintains an up to date map of the ~70 time zones that are actually mapped to a current geographical area. 

But most computers in the world use (IANA names)[https://github.com/eggert/tz], and for many computers the IANA name is one of more than 600 locations that represent historical differences in time zones across different regions. 

When creating user interfaces that deal only with the future, it would be handy to be able to map the full ~600 list to the much shorter 70 list so that it's easier for users to pick their time zone in a drop-down. 

The CSV file in output maps all IANA names to 62 'current' time zones, as well as the 48 'closest significant current' time zone where there are more than 200,000 people living. 

It also provide a list of 'windows labels' which are handy labels popular on older versions of windows for each IANA name. Windows labels are useful because they are ordered by UTC offset, and frequent travellers have an innate senese of where their time zone is on that list. A "custom label" is also provided, but this one is shorter than the windows option. 
