rmf data/edges.txt

follow_events = LOAD 'data/follow_events' USING PigStorage('\t', '-schema');
users = foreach follow_events generate $0#'payload'#'target'#'login' as followed,
                                       $0#'actor_attributes'#'login' as follower;
users = filter users by followed is not null and follower is not null;
edges = foreach (group users by (followed, follower)) generate flatten(group) as (followed, follower), 
                                                               COUNT_STAR(users) as total;   
edges = filter edges by total > 1;                                                    
store edges into 'data/edges.txt' USING PigStorage(',');
