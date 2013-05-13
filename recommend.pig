register 'distance.py' using jython as funcs;

set default_parallel 5
rmf /tmp/distances.txt

watch_events = LOAD '/tmp/WatchEvent';
watch_ratings = FOREACH watch_events GENERATE (chararray)$0#'actor'#'login' AS follower:chararray,
                                              (chararray)$0#'repo'#'name' AS repo:chararray,
                                              1.0 AS rating;
fork_event = LOAD '/tmp/ForkEvent';
fork_ratings = FOREACH fork_event GENERATE (chararray)$0#'actor'#'login' AS follower:chararray,
                                           (chararray)$0#'repo'#'name' as repo:chararray,
                                           2.0 AS rating;
all_ratings = UNION watch_ratings, fork_ratings;
differences = FOREACH (GROUP all_ratings BY repo) GENERATE FLATTEN(funcs.differences(all_ratings));
distances = FOREACH (GROUP differences BY (user1, user2)) GENERATE funcs.distance(differences);

store distances into '/tmp/distances.txt';
