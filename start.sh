# Configure db path
DB_PATH=/data/mongodb

# Killing mongo processes
echo "killing mongod and mongos..."
killall mongod
killall mongos

sleep 15

# start 3 config servers
mongod --config ./confs/config/r0.conf
mongod --config ./confs/config/r1.conf
mongod --config ./confs/config/r2.conf
echo "Ready config server"
sleep 15
# start a replica set and tell it that it will be shard0
mongod --config ./confs/shard0/r0.conf
mongod --config ./confs/shard0/r1.conf
mongod --config ./confs/shard0/r2.conf
echo "Ready shard0"
sleep 15
# start a replicate set and tell it that it will be a shard1
mongod --config ./confs/shard1/r0.conf
mongod --config ./confs/shard1/r1.conf
mongod --config ./confs/shard1/r2.conf
echo "Ready shard1"
sleep 15
# start a replicate set and tell it that it will be a shard2
mongod --config ./confs/shard2/r0.conf
mongod --config ./confs/shard2/r1.conf
mongod --config ./confs/shard2/r2.conf
echo "Ready shard2"
sleep 15
# start mongos router
mongos --config ./confs/mongos/m1.conf
mongos --config ./confs/mongos/m2.conf
echo "Ready mongos router"
