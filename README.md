github-explorer
===============

Explorer app for Github archive data

ETL for Pig
-----------
To get the JSON to load in Pig, run [newline_format.rb](https://github.com/rjurney/github-explorer/blob/master/newline_format.rb)

Splitting Events by Type
------------------------
Run [github.pig](https://github.com/rjurney/github-explorer/blob/master/github.pig) to split events by type into /tmp/<event_type>.json directories.
