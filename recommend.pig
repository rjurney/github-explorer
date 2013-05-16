register piggybank.jar
register datafu-0.0.9-SNAPSHOT.jar;

set default_parallel 50
set mapred.child.java.opts -Xmx2048m

rmf /tmp/differences.txt
rmf /tmp/distances.txt
rmf /tmp/weighted_ratings.txt
rmf /tmp/recommendations.txt
rmf /tmp/pairs.txt

DEFINE POW org.apache.pig.piggybank.evaluation.math.POW();
DEFINE ABS org.apache.pig.piggybank.evaluation.math.ABS();

/* Watch events happen whenever a user 'watches' a github project */
watch_events = LOAD '/tmp/WatchEvent';
-- watch_events = LOAD 's3://github-explorer/WatchEvent' AS (json: map[]);
watch_ratings = FOREACH watch_events GENERATE (chararray)$0#'actor'#'login' AS follower:chararray,
                                              (chararray)$0#'repo'#'name' AS repo:chararray,
                                              1.0 AS rating;

/* Fork events happen whenever a github project is 'forked' */
fork_events = LOAD '/tmp/ForkEvent';
-- fork_events = LOAD 's3://github-explorer/ForkEvent' AS (json: map[]);
fork_ratings = FOREACH fork_events GENERATE (chararray)$0#'actor'#'login' AS follower:chararray,
                                           (chararray)$0#'repo'#'name' as repo:chararray,
                                           2.0 AS rating;

/* Download events, whenever a user downloads a tarball of a repo */
download_events = LOAD '/tmp/DownloadEvent' as (json: map[]);
-- download_events = LOAD 's3://github-explorer/DownloadEvent' AS (json: map[]);
download_ratings = FOREACH download_events GENERATE (chararray)$0#'actor_attributes'#'login' AS follower:chararray,
                                                    StringConcat((chararray)$0#'repository'#'owner', '/', $0#'repository'#'name') AS repo:chararray,
                                                    1.0 AS rating;

/* Create issues events - implies a user has already downloaded/forked and tried the software */
/*issues_events = LOAD '/tmp/IssuesEvent' AS (json: map[]);
-- issues_events = LOAD 's3://github-explorer/IssuesEvent' AS (json: map[]);
issues_ratings = FOREACH issues_events GENERATE (chararray)$0#'actor_attributes'#'login' AS follower:chararray,
                                                StringConcat((chararray)$0#'repository'#'owner', '/', $0#'repository'#'name') AS repo:chararray,
                                                3.0 AS rating;*/

/* Create repository event - strongest association with a repo possible */
create_events = LOAD '/tmp/CreateEvent' as (json: map[]);
-- create_events = LOAD 's3://github-explorer/CreatEvent' AS (json: map[]);
create_ratings = FOREACH create_events GENERATE (chararray)$0#'actor_attributes'#'login' AS follower:chararray,
                                                StringConcat((chararray)$0#'repository'#'owner', '/', $0#'repository'#'name') AS repo:chararray,
                                                3.0 AS rating;

/* Combine all different event types into one global, bi-directional rating */
all_ratings = UNION watch_ratings, fork_ratings, download_ratings, create_ratings; /* issues_ratings */
all_ratings = FILTER all_ratings BY (follower IS NOT NULL) AND (repo IS NOT NULL);
/* If there are multiple events per follower/repo pair, average them into a single value */
all_ratings = FOREACH (GROUP all_ratings BY (follower, repo)) GENERATE FLATTEN(group) AS (follower, repo), 
                                                                       AVG(rating) as rating;
/* Filter the top most populate all_ratings, as their size means the computation never finishes */
sizes = FOREACH (GROUP all_ratings BY repo) GENERATE FLATTEN(all_ratings), SIZE(all_ratings) AS size;
lt_10k = FILTER sizes BY size < 10000;
lt_10k = FOREACH lt_10k GENERATE all_ratings::repo as repo, 
                                 follower as follower, 
                                 rating as rating;

/* Make the pairs from co-membership of a repo bi-directional */
front_pairs = FOREACH (GROUP lt_10k BY repo) GENERATE FLATTEN(datafu.pig.bags.UnorderedPairs(lt_10k));
back_pairs = FOREACH front_pairs GENERATE elem1 as elem2, elem2 as elem1;
pairs = UNION front_pairs, back_pairs;
/* pairs: {datafu.pig.bags.unorderedpairs_all_ratings_11::elem1: (follower: chararray,repo: chararray,rating: double),datafu.pig.bags.unorderedpairs_all_ratings_11::elem2: (follower: chararray,repo: chararray,rating: double)} */
store pairs into '/tmp/pairs.txt';

pairs = LOAD '/tmp/pairs.txt' AS (elem1:(repo:chararray, follower:chararray, rating:double), elem2:(repo:chararray, follower:chararray, rating:double));
pairs = filter pairs by elem1.follower != elem2.follower;

/* Get a Euclidian distance between all github users, starting with the difference squared */
differences = FOREACH pairs GENERATE elem1.follower AS follower1, 
                                     elem2.follower AS follower2, 
                                     elem1.repo AS repo,
                                     POW(ABS(elem1.rating - elem2.rating), 2.0) as difference;
store differences into '/tmp/differences.txt';
differences = LOAD '/tmp/differences.txt' AS (follower1:chararray, follower2:chararray, repo:chararray, difference:double);
distances = FOREACH (GROUP differences BY (follower1, follower2)) GENERATE FLATTEN(group) AS (follower1, follower2), 
                                                                           1/(1 + SQRT(SUM(differences.difference))) as distance;
store distances into '/tmp/distances.txt';
distances = LOAD '/tmp/distances.txt' AS (follower1:chararray, follower2:chararray, distance:double);

/* Now JOIN distances back to the pairs of co-followers to weight those ratings. */
pairs_and_distances = JOIN distances BY (follower1, follower2), 
                               pairs BY (elem1.follower, elem2.follower);
                               
                               
                               
                               
weighted_ratings = FOREACH pairs_and_distances GENERATE follower1 as login, 
                                                        elem2.repo as repo, 
                                                        distance as distance,
                                                        elem2.rating * distance AS weighted_rating;
store weighted_ratings into '/tmp/weighted_ratings.txt';

/* Having weighted ratings, now group by follower1 and create an ordered list - the user's recommendations */
total_weighted_ratings = FOREACH (GROUP weighted_ratings BY (login, repo)) GENERATE 
                                  FLATTEN(group) as (login, repo),
                                  SUM(weighted_ratings.weighted_rating)/SUM(weighted_ratings.distance) AS rating_total;

recommendations = FOREACH (GROUP total_weighted_ratings BY login) {
  sorted = ORDER total_weighted_ratings BY rating_total DESC;
  top_20 = LIMIT sorted 20;
  GENERATE FLATTEN(group) as login, 
           top_20.(repo, rating_total) as recommendations;
}
store recommendations into '/tmp/recommendations.txt';
