#!/bin/bash

echo "Hello Consul Client API!"

# Install Consul.  This creates...
# 1 - a default /etc/consul.d/consul.hcl
# 2 - a default systemd consul.service file
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update && apt install -y consul unzip

# Grab instance IP
local_ip=`ip -o route get to 169.254.169.254 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`

mkdir /etc/consul.d/certs

cat > /etc/consul.d/certs/consul-agent-ca.pem <<- EOF
${CA_PUBLIC_KEY}
EOF

touch /etc/consul.d/jwt

# Modify the default consul.hcl file
cat > /etc/consul.d/consul.hcl <<- EOF
data_dir = "/opt/consul"

client_addr = "0.0.0.0"

server = false

bind_addr = "0.0.0.0"

advertise_addr = "$local_ip"

verify_incoming = false

verify_outgoing = true

verify_server_hostname = true

ca_file = "/etc/consul.d/certs/consul-agent-ca.pem"

auto_config = {
  enabled = true
  intro_token_file = "/etc/consul.d/jwt"
  server_addresses = ["provider=aws tag_key=\"${PROJECT_TAG}\" tag_value=\"${PROJECT_VALUE}\""]
}

ports = {
  https = 8501
}
EOF

# Start Consul
sudo systemctl start consul

# Pull down and install Fake Service
curl -LO https://github.com/nicholasjackson/fake-service/releases/download/v0.22.7/fake_service_linux_amd64.zip
unzip fake_service_linux_amd64.zip
mv fake-service /usr/local/bin
chmod +x /usr/local/bin/fake-service

# Fake Service Systemd Unit File
cat > /etc/systemd/system/api.service <<- EOF
[Unit]
Description=API
After=syslog.target network.target

[Service]
Environment="MESSAGE=api"
Environment="NAME=api"
ExecStart=/usr/local/bin/fake-service
ExecStop=/bin/sleep 5
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload unit files and start the API
systemctl daemon-reload
systemctl start api

# Consul Config file for our fake API service
cat > /etc/consul.d/api.hcl <<- EOF
service {
  name  = "api"
  port  = 9090
  token = "${SERVICE_TOKEN}"

  check {
    id = "api"
    name = "HTTP API on Port 9090"
    http = "http://localhost:9090/health"
    interval = "30s"
  }
}
EOF

systemctl restart consul

mkdir -p /etc/systemd/resolved.conf.d

# Point DNS to Consul's DNS
cat > /etc/systemd/resolved.conf.d/consul.conf <<- EOF
[Resolve]
DNS=127.0.0.1
Domains=~consul
EOF

# Because our Ubuntu's systemd is < 245, we need to redirect traffic to the correct port for the DNS changes to take effect
iptables --table nat --append OUTPUT --destination localhost --protocol udp --match udp --dport 53 --jump REDIRECT --to-ports 8600
iptables --table nat --append OUTPUT --destination localhost --protocol tcp --match tcp --dport 53 --jump REDIRECT --to-ports 8600

# Restart systemd-resolved so that the above DNS changes take effect
systemctl restart systemd-resolved
