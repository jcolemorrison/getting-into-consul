#!/bin/bash

echo "Hello Consul Client Web!"

# Install Consul.  This creates...
# 1 - a default /etc/consul.d/consul.hcl
# 2 - a default systemd consul.service file
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update && apt install -y consul=1.12.0-1 unzip

# Install Envoy
curl https://func-e.io/install.sh | bash -s -- -b /usr/local/bin
func-e use 1.21.2
cp /root/.func-e/versions/1.21.2/bin/envoy /usr/local/bin

# Grab instance IP
local_ip=`ip -o route get to 169.254.169.254 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`

mkdir /etc/consul.d/certs

cat > /etc/consul.d/certs/consul-agent-ca.pem <<- EOF
${CA_PUBLIC_KEY}
EOF

cat > /etc/consul.d/certs/client-cert.pem <<- EOF
${CLIENT_PUBLIC_KEY}
EOF

cat > /etc/consul.d/certs/client-key.pem <<- EOF
${CLIENT_PRIVATE_KEY}
EOF

# Modify the default consul.hcl file
cat > /etc/consul.d/consul.hcl <<- EOF
datacenter = "dc1"

primary_datacenter = "dc1"

data_dir = "/opt/consul"

client_addr = "0.0.0.0"

server = false

bind_addr = "0.0.0.0"

advertise_addr = "$local_ip"

retry_join = ["provider=aws tag_key=\"${PROJECT_TAG}\" tag_value=\"${PROJECT_VALUE}\""]

encrypt = "${GOSSIP_KEY}"

verify_incoming = true

verify_outgoing = true

verify_server_hostname = true

ca_file = "/etc/consul.d/certs/consul-agent-ca.pem"

cert_file = "/etc/consul.d/certs/client-cert.pem"

key_file = "/etc/consul.d/certs/client-key.pem"

acl = {
  enabled = true
  default_policy = "deny"
  down_policy = "extend-cache"
  enable_token_persistence = true

  tokens {
    default = "" # put node-identity token here
  }
}

ports {
  grpc = 8502
}

telemetry {
  prometheus_retention_time = "24h"
  disable_hostname = true
}
EOF

# Pull down and install Fake Service
curl -LO https://github.com/nicholasjackson/fake-service/releases/download/v0.22.7/fake_service_linux_amd64.zip
unzip fake_service_linux_amd64.zip
mv fake-service /usr/local/bin
chmod +x /usr/local/bin/fake-service

# Fake Service Systemd Unit File
cat > /etc/systemd/system/web.service <<- EOF
[Unit]
Description=WEB
After=syslog.target network.target

[Service]
Environment="MESSAGE=Hello from Web"
Environment="NAME=web"
Environment="UPSTREAM_URIS=http://127.0.0.1:9091"
ExecStart=/usr/local/bin/fake-service
ExecStop=/bin/sleep 5
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload unit files and start the API
systemctl daemon-reload

# Consul Config file for our fake API service
cat > /etc/consul.d/web.hcl <<- EOF
service {
  name = "web"
  port = 9090
  token = "" # put api service token here

  check {
    id = "web"
    name = "HTTP Web on Port 9090"
    http = "http://localhost:9090/health"
    interval = "30s"
  }

  connect {
    sidecar_service {
      port = 20000
      check {
        name     = "Connect Envoy Sidecar"
        tcp      = "127.0.0.1:20000"
        interval = "10s"
      }
      proxy {
        upstreams {
          destination_name   = "api"
          local_bind_address = "127.0.0.1"
          local_bind_port    = 9091
        }
      }
    }
  }
}
EOF

cat > /etc/systemd/system/consul-envoy.service <<- EOF
[Unit]
Description=Consul Envoy
After=syslog.target network.target

# Put web service token here for the -token option!
[Service]
ExecStart=/usr/bin/consul connect envoy -sidecar-for=web -token=web_service_token
ExecStop=/bin/sleep 5
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

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
