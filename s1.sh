# Configure db path
DB_PATH=/data/mongodb

# Killing mongo processes
echo "killing mongod and mongos..."
killall mongod
killall mongos
sleep 15


# 1. start a replica set and tell it that it will be shard0
mkdir -p $DB_PATH/shard0/rs0 $DB_PATH/shard0/rs1 $DB_PATH/shard0/rs2
mongod --config ./confs/shard0/r0.conf  --tlsAllowInvalidCertificates
mongod --config ./confs/shard0/r1.conf  --tlsAllowInvalidCertificates
mongod --config ./confs/shard0/r2.conf  --tlsAllowInvalidCertificates

sleep 15
# connect to one server and initiate the set
mongosh --port 37017 --tls  --tlsAllowInvalidCertificates --host database.fluddi.com --tlsCertificateKeyFile /opt/mongodb/certificate.pem --tlsCAFile /opt/mongodb/CA.pem << 'EOF'
rs.initiate({
  _id: "s0",
  members: [
    { _id : 0, host : "database.fluddi.com:37017" },
    { _id : 1, host : "database.fluddi.com:37018" },
    { _id : 2, host : "database.fluddi.com:37019", arbiterOnly: true }
  ]
})
EOF

echo ">>>>> shard0 replica initialized"
