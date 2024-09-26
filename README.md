There are over 500 IANA timezones, but not many are meaningfuly distinct. Ideally a date-time picker should support every time zone, but not overwhelm the user with 500 options should they decide to change the time zone. 

This repo creates the concept of "iana groups" which are groups of iana time zones that are extremely similar (denoted by having the same UTC offset on "2023-01-01", "2023-03-31", "2023-07-01", and "2023-11-25" 

For each iana time zone, the iana_group is the most populous iana code time zone with the exact same time on those dates.  

A CSV file containing each iana code as well as it's iana group is in the output folder under IANA_windows_lookup.csv. 

Some particualrly annoying iana time zones are excluded (e.g. Antarctica, anywhere with a population <20,000). 

I also provide a list of 'windows labels' which are handy labels popular on older versions of windows for each IANA code. Windows labels are useful because they are ordered by UTC offset, and frequent travellers have an innate senese of where their time zone is on that list relative to UTC. 

If you are creating a date/time picker, you might decide to support every single user's system IANA code for the 'default' time zone, but only allow users to change to one of the unique iana_group values in a drop down selector menu. The order of the menu should be related to windows_group_display, and the values could be either the windows_group_display or the iana_group value.

This repo also provides abbreviations for each time zone. The abbreviation has been set to the 3 digit 'standard' time used in that timezone when daylight savings is not in effect. Note that while this is convenient - ideally you'd use a user's system abbreviations so that the 3 digit code updates during daylight savings periods. For the USA/Canada this has been solved in this dataset by using two letter abbreviations for Eastern Time/Central Time/Mountain Time/Pacific Time.
