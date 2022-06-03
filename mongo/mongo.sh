cat <<EOF >/usr/lib/systemd/system/mongod-master.service

[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network.target

[Service]
User=mongo
Group=mongo
ExecStart=/usr/local/mongodb/bin/mongod -f /server/mongodb/master/conf/mongo.conf
ExecStartPre=/usr/bin/chown -R mongo:mongo /server/mongodb/master/
ExecStop=/usr/local/mongodb/bin/mongod -f /server/mongodb/master/conf/mongo.conf --shutdown
PermissionsStartOnly=true
PIDFile=/server/mongodb/master/pid/master.pid
Type=forking

[Install]
WantedBy=multi-user.target
EOF