There are over 500 IANA timezones, but not many are meaningfuly distinct. 

This repo creates a concept of "iana groups" which are groups of iana time codes that are extremely similar (denoted by having the same UTC offset on "2023-01-01", "2023-03-31", "2023-07-01", and "2023-11-25" 

For each iana code, the iana_group is the most populous iana code time zone with the exact times.  

Some particualrly annoying iana time zones are excluded (e.g. Antarctica). 

I also provide a list of 'windows labels' which are handy labels popular on older versions of windows for each IANA code, but also each IANA group. Windows labels are useful because they are ordered by UTC offset, and frequent travellers have an innate senese of where their time zone is on that list. 

The relevant output is in the output folder under IANA_windows_lookup.csv. 

If you are creating a date/time picker, you might decide to support every single user's system IANA code for the 'default' time zone, but only allow users to change to one of the unique iana_group values in a drop down selector menu. You may also then choose to display windows_group_display as the order and/or display for each iana group. 
