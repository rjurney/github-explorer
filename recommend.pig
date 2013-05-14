register 'distance.py' using jython as funcs;
register piggybank.jar
register datafu-0.0.9-SNAPSHOT.jar;

set default_parallel 100
set mapred.child.java.opts -Xmx2048m
rmf /tmp/distances.txt

DEFINE POW org.apache.pig.piggybank.evaluation.math.POW();
DEFINE ABS org.apache.pig.piggybank.evaluation.math.ABS();

/*
bin/hadoop distcp s3n://github-explorer/WatchEvent /tmp/
bin/hadoop distcp s3n://github-explorer/ForkEvent /tmp/
*/

watch_events = LOAD '/tmp/WatchEvent';
-- watch_events = LOAD 's3://github-explorer/WatchEvent' AS (json: map[]);
watch_ratings = FOREACH watch_events GENERATE (chararray)$0#'actor'#'login' AS follower:chararray,
                                              (chararray)$0#'repo'#'name' AS repo:chararray,
                                              1.0 AS rating;
fork_event = LOAD '/tmp/ForkEvent';
-- fork_event = LOAD 's3://github-explorer/ForkEvent' AS (json: map[]);
fork_ratings = FOREACH fork_event GENERATE (chararray)$0#'actor'#'login' AS follower:chararray,
                                           (chararray)$0#'repo'#'name' as repo:chararray,
                                           2.0 AS rating;
all_ratings = UNION watch_ratings, fork_ratings;
all_ratings = FILTER all_ratings BY (follower IS NOT NULL) AND (repo IS NOT NULL);
pairs = FOREACH (GROUP all_ratings BY repo) GENERATE FLATTEN(datafu.pig.bags.UnorderedPairs(all_ratings));
/* 
differences: {
  datafu.pig.bags.unorderedpairs_all_ratings_15::elem1: (follower: chararray,repo: chararray,rating: double),
  datafu.pig.bags.unorderedpairs_all_ratings_15::elem2: (follower: chararray,repo: chararray,rating: double)
} */
differences = FOREACH pairs GENERATE elem1.follower AS follower1, 
                                     elem2.follower AS follower2, 
                                     elem1.repo AS repo,
                                     POW(ABS(elem1.rating - elem2.rating), 2.0) as difference;
store differences into '/tmp/differences.txt';
distances = FOREACH (GROUP differences BY (follower1, follower2)) GENERATE FLATTEN(group) AS (follower1, follower2), 
                                                                           funcs.distance(differences) as distance;

/*
hadoop distcp /tmp/distances.txt s3n://github-explorer/distances.txt
*/
store distances into '/tmp/distances.txt';