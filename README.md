github-explorer
===============

Explorer app for Github archive data

Getting the Data
----------------
To get all data for the years 2011-2013, run: [get_all_data.rb](https://github.com/rjurney/github-explorer/blob/master/get_all_data.rb) 404 errors are normal at the beginning of the download, as events only started in February.

ETL for Pig
-----------
To get the JSON to load in Pig, we must format the JSON to one object per line. To achieve this, run [newline_format.rb](https://github.com/rjurney/github-explorer/blob/master/newline_format.rb)

Splitting Events by Type
------------------------
Run [split_events.pig](https://github.com/rjurney/github-explorer/blob/master/split_events.pig) to split events by type into a dozen /tmp/<event_type> directories. These event types can then be analyzed independently.

Building Recommendations
------------------------
Next we use Pig and Jython to create repository recommendations for all github users.

Run [recommend.pig](https://github.com/rjurney/github-explorer/blob/master/recommend.pig), which uses [distance.py](https://github.com/rjurney/github-explorer/blob/master/distance.py) to calculate a user-based recommendation. It is based on the example from Programming Collective Intelligence, albeit scaled for the size of the data (Pig, Hadoop, ElasticMapReduce). Pearson correlation coefficient are calculated between all users, and then a user's recommendations are weighted by this value.

Publishing Recommendations
--------------------------
Next, run [load_mongo.pig](https://github.com/rjurney/github-explorer/blob/master/load_mongo.pig), which will load MongoDB with the recommendations. In addition, create the following index in MongoDB:

```
mongo recommendations
> db.recommendations.ensureIndex({login: 1})
```