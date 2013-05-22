scp -i ~/.ssh/github-explorer.pem recommend.pig $1:
scp -i ~/.ssh/github-explorer.pem udfs.py $1:
scp -i ~/.ssh/github-explorer.pem ~/Software/pig/contrib/piggybank/java/piggybank.jar $1:
scp -i ~/.ssh/github-explorer.pem ~/Software/datafu/dist/datafu-0.0.9-SNAPSHOT.jar $1:
scp -i ~/.ssh/github-explorer.pem distcp.sh $1: