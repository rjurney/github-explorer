register /me/Software/elephant-bird/pig/target/elephant-bird-pig-3.0.6-SNAPSHOT.jar
register /me/Software/pig/build/ivy/lib/Pig/json-simple-1.1.jar
set elephantbird.jsonloader.nestedLoad 'true'

rmf /tmp/FollowEvent.json

set default_parallel 10

github_events = load '/tmp/newline.json' using com.twitter.elephantbird.pig.load.JsonLoader() as json:map[];

SPLIT github_events INTO CommitCommentEvent IF $0#'type' == 'CommitCommentEvent',
                         CreateEvent IF $0#'type'        == 'CreateEvent',
                         DeleteEvent IF $0#'type'        == 'DeleteEvent',
                         DownloadEvent IF $0#'type'      == 'DownloadEvent',
                         FollowEvent IF $0#'type'        == 'FollowEvent',
                         ForkEvent IF $0#'type'          == 'ForkEvent',
                         ForkApplyEvent IF $0#'type'     == 'ForkApplyEvent',
                         GistEvent IF $0#'type'          == 'GistEvent',
                         GollumEvent IF $0#'type'        == 'GollumEvent',
                         IssueCommentEvent IF $0#'type'  == 'IssueCommentEvent',
                         IssuesEvent IF $0#'type'        == 'IssuesEvent',
                         MemberEvent IF $0#'type'        == 'MemberEvent',
                         PublicEvent IF $0#'type'        == 'Public Event',
                         PullRequestEvent IF $0#'type'   == 'PullRequestEvent',
                         PullRequestReviewCommentEvent IF $0#'type' == 'PullRequestReviewCommentEvent',
                         PushEvent IF $0#'type'          == 'PushEvent',
                         TeamAddEvent IF $0#'type'       == 'TeamAddEvent',
                         WatchEvent IF $0#'type'         == 'WatchEvent';

STORE CommitCommentEvent INTO '/tmp/CommitCommentEvent' USING PigStorage('\t','-schema');
STORE CreateEvent INTO '/tmp/CreateEvent' USING PigStorage('\t','-schema');
STORE DeleteEvent INTO '/tmp/DeleteEvent' USING PigStorage('\t','-schema');
STORE DownloadEvent INTO '/tmp/DownloadEvent' USING PigStorage('\t','-schema');
STORE FollowEvent INTO '/tmp/FollowEvent' USING PigStorage('\t','-schema');
STORE ForkEvent INTO '/tmp/ForkEvent' USING PigStorage('\t','-schema');
STORE ForkApplyEvent INTO '/tmp/ForkApplyEvent' USING PigStorage('\t','-schema');
STORE GistEvent INTO '/tmp/GistEvent' USING PigStorage('\t','-schema');
STORE GollumEvent INTO '/tmp/GollumEvent' USING PigStorage('\t','-schema');
STORE IssueCommentEvent INTO '/tmp/IssueCommentEvent' USING PigStorage('\t','-schema');
STORE IssuesEvent INTO '/tmp/IssuesEvent' USING PigStorage('\t','-schema');
STORE MemberEvent INTO '/tmp/MemberEvent' USING PigStorage('\t','-schema');
STORE PublicEvent INTO '/tmp/PublicEvent' USING PigStorage('\t','-schema');
STORE PullRequestEvent INTO '/tmp/PullRequestEvent' USING PigStorage('\t','-schema');
STORE PullRequestReviewCommentEvent INTO '/tmp/PullRequestReviewCommentEvent' USING PigStorage('\t','-schema');
STORE PushEvent INTO '/tmp/PushEvent' USING PigStorage('\t','-schema');
STORE TeamAddEvent INTO '/tmp/TeamAddEvent' USING PigStorage('\t','-schema');
STORE WatchEvent INTO '/tmp/WatchEvent' USING PigStorage('\t','-schema');



