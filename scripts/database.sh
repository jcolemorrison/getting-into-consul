#!/bin/bash

echo "Hello Consul Client DATABASE!"

apt update && apt install -y unzip

# Pull down and install Fake Service
curl -LO https://github.com/nicholasjackson/fake-service/releases/download/v0.22.7/fake_service_linux_amd64.zip
unzip fake_service_linux_amd64.zip
mv fake-service /usr/local/bin
chmod +x /usr/local/bin/fake-service

# Fake Service Systemd Unit File
cat > /etc/systemd/system/database.service <<- EOF
[Unit]
Description=database
After=syslog.target network.target

[Service]
Environment="MESSAGE=database"
Environment="NAME=database"
Environment="LISTEN_ADDR=0.0.0.0:5432"
ExecStart=/usr/local/bin/fake-service
ExecStop=/bin/sleep 5
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload unit files and start the database
systemctl daemon-reload
systemctl start database
