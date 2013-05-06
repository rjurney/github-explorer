register /me/Software/elephant-bird/pig/target/elephant-bird-pig-3.0.6-SNAPSHOT.jar
register /me/Software/pig/build/ivy/lib/Pig/json-simple-1.1.jar
set elephantbird.jsonloader.nestedLoad 'true'


github_events = load 'data/*.newline.json' using com.twitter.elephantbird.pig.load.JsonLoader() as json:map[];

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

STORE CommitCommentEvent INTO '/tmp/CommitCommentEvent.json';
STORE CreateEvent INTO '/tmp/CreateEvent.json';
STORE DeleteEvent INTO '/tmp/DeleteEvent.json';
STORE DownloadEvent INTO '/tmp/DownloadEvent.json';
STORE FollowEvent INTO '/tmp/FollowEvent.json';
STORE ForkEvent INTO '/tmp/ForkEvent.json';
STORE ForkApplyEvent INTO '/tmp/ForkApplyEvent.json';
STORE GistEvent INTO '/tmp/GistEvent.json';
STORE GollumEvent INTO '/tmp/GollumEvent.json';
STORE IssueCommentEvent INTO '/tmp/IssueCommentEvent.json';
STORE IssuesEvent INTO '/tmp/IssuesEvent.json';
STORE MemberEvent INTO '/tmp/MemberEvent.json';
STORE PublicEvent INTO '/tmp/PublicEvent.json';
STORE PullRequestEvent INTO '/tmp/PullRequestEvent.json';
STORE PullRequestReviewCommentEvent INTO '/tmp/PullRequestReviewCommentEvent.json';
STORE PushEvent INTO '/tmp/PushEvent.json';
STORE TeamAddEvent INTO '/tmp/TeamAddEvent.json';
STORE WatchEvent INTO '/tmp/WatchEvent.json';



