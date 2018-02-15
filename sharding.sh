# Configure db path
DB_PATH=/data/mongodb

# Killing mongo processes
echo "killing mongod and mongos..."
killall mongod
killall mongos

# start a replica set and tell it that it will be shard0
mkdir -p $DB_PATH/shard0/rs0 $DB_PATH/shard0/rs1 $DB_PATH/shard0/rs2
mongod --config ./confs/shard0/r0.conf
mongod --config ./confs/shard0/r1.conf
mongod --config ./confs/shard0/r2.conf

sleep 5
# connect to one server and initiate the set
mongo --port 37017 --ssl --host database.crazyengage.com --sslPEMKeyFile /opt/mongodb/crazyengage.pem --sslCAFile /opt/mongodb/CA.pem << 'EOF'
rs.initiate({
  _id: "s0",
  members: [
    { _id : 0, host : "localhost:37017" },
    { _id : 1, host : "localhost:37018" },
    { _id : 2, host : "localhost:37019", arbiterOnly: true }
  ]
})

db.getSiblingDB("admin").createUser(
  {
    user: "shard0",
    pwd: "grw@123",
    roles: [
      { role: "userAdminAnyDatabase", db: "admin" },
    ]
  }
)
EOF

# start a replicate set and tell it that it will be a shard1
mkdir -p $DB_PATH/shard1/rs0 $DB_PATH/shard1/rs1 $DB_PATH/shard1/rs2
mongod --config ./confs/shard1/r0.conf
mongod --config ./confs/shard1/r1.conf
mongod --config ./confs/shard1/r2.conf

sleep 5

mongo --port 47017 << 'EOF'
rs.initiate({
  _id: "s1",
  members: [
    { _id : 0, host : "localhost:47017" },
    { _id : 1, host : "localhost:47018" },
    { _id : 2, host : "localhost:47019", arbiterOnly: true }
  ]
})

db.getSiblingDB("admin").createUser(
  {
    user: "shard1",
    pwd: "grw@123",
    roles: [
      { role: "userAdminAnyDatabase", db: "admin" },
    ]
  }
)
EOF

# start a replicate set and tell it that it will be a shard2
mkdir -p $DB_PATH/shard2/rs0 $DB_PATH/shard2/rs1 $DB_PATH/shard2/rs2
mongod --config ./confs/shard2/r0.conf
mongod --config ./confs/shard2/r1.conf
mongod --config ./confs/shard2/r2.conf

sleep 5

mongo --port 57017 << 'EOF'
rs.initiate({
  _id: "s2",
  members: [
    { _id : 0, host : "localhost:57017" },
    { _id : 1, host : "localhost:57018" },
    { _id : 2, host : "localhost:57019", arbiterOnly: true }
  ]
})

db.getSiblingDB("admin").createUser(
  {
    user: "shard2",
    pwd: "grw@123",
    roles: [
      { role: "userAdminAnyDatabase", db: "admin" },
    ]
  }
)
EOF


# now start 3 config servers
mkdir -p $DB_PATH/config/rs0 $DB_PATH/config/rs1 $DB_PATH/config/rs2 
mongod --config ./confs/config/r0.conf
mongod --config ./confs/config/r1.conf
mongod --config ./confs/config/r2.conf

sleep 5

mongo --port 57040 << 'EOF'
rs.initiate({
	_id: "cfg",
	configsvr: true,
	members: [
    { _id : 0, host : "localhost:57040" },
    { _id : 1, host : "localhost:57041" },
    { _id : 2, host : "localhost:57042" }
  ]
})
EOF

# now start the mongos on port 27018
mongos --config ./confs/mongos/m1.conf
echo "Waiting 60 seconds for the replica sets to fully come online"
sleep 60
echo "Connnecting to mongos and enabling sharding"

# add shards and enable sharding on the growthfunnel db
mongo --port 27018 << 'EOF'

# Create an super administrator 
use admin
db.createUser(
  {
    user: "admin",
    pwd: "grw@123",
    roles: [
      { role: "userAdminAnyDatabase", db: "admin" },
      { role : "clusterAdmin", db : "admin" }
    ]
  }
)
db.auth("admin", "grw@123")

# Do sharding
sh.addShard("s0/localhost:37017")
sh.addShard("s1/localhost:47017")
sh.addShard("s2/localhost:57017")
sh.enableSharding("growthfunnel")

# Create an administrator for growthfunnel
use growthfunnel
db.createUser(
  {
    user: "grw-admin",
    pwd: "grw@123",
    roles: [
      { role: "dbOwner", db: "growthfunnel" },
      { role : "clusterAdmin", db : "admin" }
    ]
  }
)

db.auth("grw-admin", "grw@123")

# Create an application user
db.createUser(
  {
    user: "webapp",
    pwd: "grw@123",
    roles: [ { role: "readWrite", db: "growthfunnel" } ]
  }
)

# Create an observer user
db.createUser(
  {
    user: "observer",
    pwd: "grw@123",
    roles: [ { role: "read", db: "growthfunnel" } ]
  }
)

db.createCollection("visitors")
db.visitors.ensureIndex({"siteId": 1, "_id": 1})
sh.shardCollection("growthfunnel.visitors", {"siteId": 1, "_id": 1})
EOF

sleep 5
echo "Done setting up sharded environment on localhost"