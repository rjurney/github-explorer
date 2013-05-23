github-explorer
===============

Recommender system for Github, built from the archive data using [Amazon Elastic MapReduce](http://aws.amazon.com/elasticmapreduce/), [Hadoop](http://hadoop.apache.org/), [Apache Pig](http://http://pig.apache.org/), [Piggybank](https://cwiki.apache.org/confluence/display/PIG/PiggyBank), [DataFu](https://github.com/linkedin/datafu) and [Jython](http://www.jython.org/) [User Defined Functions (UDFs)](http://pig.apache.org/docs/r0.11.0/udf.html).

Getting the Github Data
-----------------------
To fetch all data for the years 2011-2013 from Amazon S3, run: [get_all_data.rb](https://github.com/rjurney/github-explorer/blob/master/get_all_data.rb) 404 errors are normal at the beginning of the download, as events only started in February but it begins iterating at the beginning of the year.

ETL for Pig
-----------
To get the JSON to load in Pig, we must format the JSON to one object per line. To achieve this, run [newline_format.rb](https://github.com/rjurney/github-explorer/blob/master/newline_format.rb). This command can be run locally.

Splitting Events by Type
------------------------
Run [split_events.pig](https://github.com/rjurney/github-explorer/blob/master/split_events.pig) to split events by type into a dozen /tmp/<event_type> directories. These event types can then be analyzed independently. For me the data quickly increased in size when I started looking at social data to the point that Hadoop was necessary.

Building Recommendations
------------------------
Next we use Pig to create repository recommendations for all github repositories.

Run [recommend.pig](https://github.com/rjurney/github-explorer/blob/master/recommend.pig), which uses [udfs.py](https://github.com/rjurney/github-explorer/blob/master/udfs.py) to calculate a pearson distance between all repos using an inferred rating system. It is based on the example from Programming Collective Intelligence, albeit scaled for the size of the data (Pig, Hadoop, ElasticMapReduce). Pearson correlation coefficient are calculated between all users, and then a user's recommendations are weighted by this value.

The rating system is as follows: 

* Watch Repository:    1.0
* Download Repository: 1.0
* Create Issue:        2.0
* Fork Repository:     3.0
* Create Repository:   4.0

Specifically, the code is:

```
/* Watch events happen whenever a user 'watches' a github project */
watch_events = LOAD 's3://github-explorer/WatchEvent' AS (json: map[]);
watch_ratings = FOREACH watch_events GENERATE (chararray)$0#'actor'#'login' AS follower:chararray,
                                              (chararray)$0#'repo'#'name' AS repo:chararray,
                                              1.0 AS rating;

/* Fork events happen whenever a github project is 'forked' */
fork_events = LOAD 's3://github-explorer/ForkEvent' AS (json: map[]);
fork_ratings = FOREACH fork_events GENERATE (chararray)$0#'actor'#'login' AS follower:chararray,
                                           (chararray)$0#'repo'#'name' as repo:chararray,
                                           3.0 AS rating;

/* Download events, whenever a user downloads a tarball of a repo */
download_events = LOAD 's3://github-explorer/DownloadEvent' AS (json: map[]);
download_ratings = FOREACH download_events GENERATE (chararray)$0#'actor_attributes'#'login' AS follower:chararray,
                                                    StringConcat((chararray)$0#'repository'#'owner', '/', $0#'repository'#'name') AS repo:chararray,
                                                    1.0 AS rating;

/* Create issues events - implies a user has already downloaded/forked and tried the software */
issues_events = LOAD 's3://github-explorer/IssuesEvent' AS (json: map[]);
issues_ratings = FOREACH issues_events GENERATE (chararray)$0#'actor_attributes'#'login' AS follower:chararray,
                                                StringConcat((chararray)$0#'repository'#'owner', '/', $0#'repository'#'name') AS repo:chararray,
                                                2.0 AS rating;

/* Create repository event - strongest association with a repo possible */
create_events = LOAD 's3://github-explorer/CreateEvent' AS (json: map[]);
create_ratings = FOREACH create_events GENERATE (chararray)$0#'actor_attributes'#'login' AS follower:chararray,
                                                StringConcat((chararray)$0#'repository'#'owner', '/', $0#'repository'#'name') AS repo:chararray,
                                                4.0 AS rating;
```

Publishing Recommendations
--------------------------
Next, run [load_mongo.pig](https://github.com/rjurney/github-explorer/blob/master/load_mongo.pig), which will load MongoDB with the recommendations. You'll need to edit the paths and hostname for your mongodb server. In addition, create the following index in MongoDB:

```
mongo recommendations
> db.recommendations.ensureIndex({login: 1})
```

Running the Application
-----------------------
Loren ipsum
