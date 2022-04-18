# Generate Consul gossip encryption key
resource "random_id" "gossip_key" {
  byte_length = 32
}

## Set bootstrap ACL token
resource "random_uuid" "consul_bootstrap_token" {}