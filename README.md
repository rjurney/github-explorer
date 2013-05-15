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

Building Recommendations
------------------------
Run [recommend.pig](https://github.com/rjurney/github-explorer/blob/master/recommend.pig), which uses [distance.py](https://github.com/rjurney/github-explorer/blob/master/distance.py) to calculate a user-based recommendation. It is based on the example from Programming Collective Intelligence, albeit scaled for the size of the data (Pig, Hadoop, ElasticMapReduce). Euclidian distances (primitive) are calculated between all users, and then a user's recommendations are normalized by this value.