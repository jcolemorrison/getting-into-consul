#!/bin/bash

echo "Hello Consul Client CTS!"

# Install Consul.  This creates...
# 1 - a default /etc/consul.d/consul.hcl
# 2 - a default systemd consul.service file
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update && apt install -y consul=1.12.0-1 unzip wget

# Install Consul Terraform Sync
wget https://releases.hashicorp.com/consul-terraform-sync/0.6.0/consul-terraform-sync_0.6.0_linux_amd64.zip
unzip consul-terraform-sync_0.6.0_linux_amd64.zip
mv consul-terraform-sync /usr/local/bin/consul-terraform-sync

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

# TODO: make systemd file for CTS bin and daemon-reload

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