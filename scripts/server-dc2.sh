#!/bin/bash

echo "Hello Consul Server DC2!"

# Install Consul.  This creates...
# 1 - a default /etc/consul.d/consul.hcl
# 2 - a default systemd consul.service file
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
# change to 1.11.3
apt update && apt install -y consul=1.11.3

# Grab instance IP
local_ip=`ip -o route get to 169.254.169.254 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`

mkdir /etc/consul.d/certs

cat > /etc/consul.d/certs/consul-agent-ca.pem <<- EOF
${CA_PUBLIC_KEY}
EOF

cat > /etc/consul.d/certs/server-cert.pem <<- EOF
${SERVER_PUBLIC_KEY}
EOF

cat > /etc/consul.d/certs/server-key.pem <<- EOF
${SERVER_PRIVATE_KEY}
EOF

# Modify the default consul.hcl file
cat > /etc/consul.d/consul.hcl <<- EOF
datacenter = "dc2"

primary_datacenter = "dc1"

data_dir = "/opt/consul"

client_addr = "0.0.0.0"

ui_config {
  enabled = true
}

acl = {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
  enable_token_replication = true
  tokens = {
    master = "${BOOTSTRAP_TOKEN}"
    agent = "${BOOTSTRAP_TOKEN}"
    replication = "" ## add acl replication token
  }
}

server = true

bind_addr = "$local_ip"

advertise_addr = "$local_ip"

bootstrap_expect=${BOOTSTRAP_NUMBER}

retry_join = ["provider=aws tag_key=\"${PROJECT_TAG}\" tag_value=\"${PROJECT_VALUE}\""]

encrypt = "${GOSSIP_KEY}"

verify_incoming = true

verify_outgoing = true

verify_server_hostname = true

ca_file = "/etc/consul.d/certs/consul-agent-ca.pem"

cert_file = "/etc/consul.d/certs/server-cert.pem"

key_file = "/etc/consul.d/certs/server-key.pem"

# Below is what's required for service mesh
ports {
  grpc = 8502
}

connect {
  enabled = true
  enable_mesh_gateway_wan_federation = true
}

primary_gateways = ["${PRIMARY_GATEWAY_IP_ADDRESS}:8443"]

# these are the default settings used for the proxies
# the equivalent for services is "service-defaults" in the "kind" argument
config_entries {
  bootstrap = [
    {
      kind = "proxy-defaults"
      name = "global"
      config {
        protocol                   = "http"
        envoy_prometheus_bind_addr = "0.0.0.0:9102"
      }
      mesh_gateway = {
        mode = "local"
      }
    }
  ]
}
EOF