github-explorer
===============

Explorer app for Github archive data

Getting the Data
----------------
To get all data for the years 2012-2013, run: [get_all_data.rb](https://github.com/rjurney/github-explorer/blob/master/get_all_data.rb)

ETL for Pig
-----------
To get the JSON to load in Pig, run [newline_format.rb](https://github.com/rjurney/github-explorer/blob/master/newline_format.rb)

Splitting Events by Type
------------------------
Run [split_events.pig](https://github.com/rjurney/github-explorer/blob/master/split_events.pig) to split events by type into a dozen /tmp/<event_type>.json directories.
