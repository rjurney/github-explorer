/* Set Home Directory - where we install software */
%default HOME `echo \$HOME/Software/`

/* MongoDB libraries and configuration */
REGISTER $HOME/mongo-hadoop/mongo-2.10.1.jar
REGISTER $HOME/mongo-hadoop/core/target/mongo-hadoop-core-1.1.0-SNAPSHOT.jar
REGISTER $HOME/mongo-hadoop/pig/target/mongo-hadoop-pig-1.1.0-SNAPSHOT.jar

DEFINE MongoStorage com.mongodb.hadoop.pig.MongoStorage();

recommendations = LOAD 'recs.txt' AS (repo:chararray, recommendations:{t:(repo:chararray, rating:double)});
store recommendations into 'mongodb://localhost/recommendations.recommendations' using MongoStorage();
