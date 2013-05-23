register piggybank.jar
register datafu-0.0.9-SNAPSHOT.jar
register 'udfs.py' using jython as udfs;

set default_parallel 50
set mapred.child.java.opts -Xmx2048m

rmf /tmp/pairs.txt
rmf /tmp/differences.txt
rmf /tmp/distances.txt
rmf /tmp/pearson.txt
rmf /tmp/ratings_and_distances.txt
rmf /tmp/weighted_ratings.txt
rmf /tmp/total_weighted_ratings.txt
rmf /tmp/recommendations.txt

DEFINE POW org.apache.pig.piggybank.evaluation.math.POW();
DEFINE ABS org.apache.pig.piggybank.evaluation.math.ABS();
DEFINE SQRT org.apache.pig.piggybank.evaluation.math.SQRT();

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
                                           3.0 AS rating;

/* Download events, whenever a user downloads a tarball of a repo */
download_events = LOAD '/tmp/DownloadEvent' as (json: map[]);
-- download_events = LOAD 's3://github-explorer/DownloadEvent' AS (json: map[]);
download_ratings = FOREACH download_events GENERATE (chararray)$0#'actor_attributes'#'login' AS follower:chararray,
                                                    StringConcat((chararray)$0#'repository'#'owner', '/', $0#'repository'#'name') AS repo:chararray,
                                                    1.0 AS rating;

/* Create issues events - implies a user has already downloaded/forked and tried the software */
issues_events = LOAD '/tmp/IssuesEvent' AS (json: map[]);
-- issues_events = LOAD 's3://github-explorer/IssuesEvent' AS (json: map[]);
issues_ratings = FOREACH issues_events GENERATE (chararray)$0#'actor_attributes'#'login' AS follower:chararray,
                                                StringConcat((chararray)$0#'repository'#'owner', '/', $0#'repository'#'name') AS repo:chararray,
                                                2.0 AS rating;

/* Create repository event - strongest association with a repo possible */
create_events = LOAD '/tmp/CreateEvent' as (json: map[]);
-- create_events = LOAD 's3://github-explorer/CreateEvent' AS (json: map[]);
create_ratings = FOREACH create_events GENERATE (chararray)$0#'actor_attributes'#'login' AS follower:chararray,
                                                StringConcat((chararray)$0#'repository'#'owner', '/', $0#'repository'#'name') AS repo:chararray,
                                                4.0 AS rating;

/* Combine all different event types into one global, bi-directional rating */
all_ratings = UNION watch_ratings, fork_ratings, create_ratings, download_ratings, issues_ratings;
all_ratings = FILTER all_ratings BY (follower IS NOT NULL) AND (repo IS NOT NULL);
/* If there are multiple events per follower/repo pair, average them into a single value */
all_ratings = FOREACH (GROUP all_ratings BY (follower, repo)) GENERATE FLATTEN(group) AS (follower, repo), 
                                                                       MAX(all_ratings.rating) as rating; /* SUM? */
/* Filter the top most populate all_ratings, as their size means the computation never finishes */
sizes = FOREACH (GROUP all_ratings BY follower) GENERATE FLATTEN(all_ratings), COUNT_STAR(all_ratings) AS size;
lt_10k = FILTER sizes BY size < 1000;
lt_10k = FOREACH lt_10k GENERATE all_ratings::repo as repo, 
                                 follower as follower, 
                                 rating as rating;

/* Emit all co-ratings per login */
front_pairs = FOREACH (GROUP lt_10k BY follower) GENERATE FLATTEN(datafu.pig.bags.UnorderedPairs(lt_10k)) AS (elem1, elem2);
back_pairs = FOREACH front_pairs GENERATE elem1 as elem2, elem2 as elem1;
pairs = UNION front_pairs, back_pairs;
--pairs = filter pairs by elem1.follower != elem2.follower;
pairs = FOREACH pairs GENERATE elem1.follower AS follower, 
                               elem1.repo AS repo1,
                               elem2.repo AS repo2,
                               elem1.rating AS rating1,
                               elem2.rating AS rating2;
store pairs into '/tmp/pairs.txt';
pairs = LOAD '/tmp/pairs.txt' AS (follower:chararray, repo1:chararray, repo2:chararray, rating1:double, rating2:double);

/* Get a Pearson's correlation coefficient between all github users, in two steps (merged by Pig into one M/R job) */
by_repos = GROUP pairs BY (repo1, repo2);
pearson = FOREACH by_repos GENERATE FLATTEN(group) AS (repo1, repo2), udfs.pearsons(pairs.rating1, pairs.rating2) AS distance;
pearson = FILTER pearson BY distance > 0;
store pearson into '/tmp/pearson.txt';
pearson = LOAD '/tmp/pearson.txt' AS (repo1:chararray, repo2:chararray, distance:double);

per_repo_recs = FOREACH (group pearson by repo1) {
  sorted = ORDER pearson BY distance DESC;
  top_20 = LIMIT sorted 20;
  GENERATE group AS repo, top_20.(repo2, distance) AS recs;
};

store per_repo_recs INTO '/tmp/recommendations.txt';


/* Now JOIN distances back to the pairs of co-followers to weight those ratings. */
ratings_and_distances = JOIN pearson BY repo2, 
                             lt_10k  BY repo USING 'skewed' PARALLEL 100;
store ratings_and_distances into '/tmp/ratings_and_distances.txt';       
               
weighted_ratings = FOREACH ratings_and_distances GENERATE follower as login, 
                                                          repo as repo, 
                                                          distance as distance,
                                                          rating * distance AS weighted_rating;
store weighted_ratings into '/tmp/weighted_ratings.txt';
-- weighted_ratings = LOAD '/tmp/weighted_ratings.txt' AS (login:chararray, repo:chararray, distance:double, weighted_rating:double);
/* Having weighted ratings, now group by follower1 and create an ordered list - the user's recommendations */
total_weighted_ratings = FOREACH (GROUP weighted_ratings BY (login, repo)) GENERATE 
                                  FLATTEN(group) as (login, repo),
                                  SUM(weighted_ratings.weighted_rating)/SUM(weighted_ratings.distance) AS rating_total;
--store total_weighted_ratings INTO '/tmp/total_weighted_ratings.txt';
-- total_weighted_ratings = LOAD '/tmp/total_weighted_ratings.txt' AS (login:chararray, repo:chararray, rating_total:double);
recommendations = FOREACH (GROUP total_weighted_ratings BY login) {
  sorted = ORDER total_weighted_ratings BY rating_total DESC;
  top_20 = LIMIT sorted 20;
  GENERATE group as login, 
           top_20.(repo, rating_total) as recommendations;
}
--store recommendations into '/tmp/recommendations.txt';
