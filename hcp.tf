# Create the HCP Consul Cluster
resource "hcp_hvn" "consul" {
  hvn_id         = "${var.main_project_tag}-main-hvn"
  cloud_provider = "aws"
  region         = var.hcp_default_region
  cidr_block     = var.hcp_vpc_cidr
}

resource "hcp_consul_cluster" "consul" {
  cluster_id      = "${var.main_project_tag}-consul-cluster"
  hvn_id          = hcp_hvn.consul.hvn_id
  tier            = "development"
  datacenter      = "dc1"
  public_endpoint = true
}

# Connect Main VPC to HVN via Peering
resource "hcp_aws_network_peering" "consul" {
  hvn_id          = hcp_hvn.consul.hvn_id
  peering_id      = var.main_project_tag
  peer_vpc_id     = aws_vpc.consul.id
  peer_account_id = aws_vpc.consul.owner_id
  peer_vpc_region = var.aws_default_region
}

resource "hcp_hvn_route" "hcp_to_vpc" {
  hvn_link         = hcp_hvn.consul.self_link
  hvn_route_id     = "${var.main_project_tag}-vpc"
  destination_cidr = aws_vpc.consul.cidr_block
  target_link      = hcp_aws_network_peering.consul.self_link
}

resource "aws_route" "hcp_consul" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = var.hcp_vpc_cidr
  vpc_peering_connection_id = hcp_aws_network_peering.consul.provider_peering_id
  depends_on                = [aws_route_table.private]
}

resource "aws_vpc_peering_connection_accepter" "hcp_consul" {
  vpc_peering_connection_id = hcp_aws_network_peering.consul.provider_peering_id
  auto_accept               = true
}

# HCP Security Groups - allow access to the HVN
resource "aws_security_group" "hcp_consul_client" {
  name_prefix = "${var.main_project_tag}-hcp-consul-client-sg"
  description = "Firewall for hcp consul clients."
  vpc_id      = aws_vpc.consul.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-hcp-consul-client-sg" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_security_group_rule" "hcp_consul_client_allow_8301_tcp" {
  security_group_id = aws_security_group.hcp_consul_client.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [var.hcp_vpc_cidr]
  description       = "Allow gossip traffic from HCP Consul Clients to HCP Cluster."
}

resource "aws_security_group_rule" "hcp_consul_client_allow_8301_udp" {
  security_group_id = aws_security_group.hcp_consul_client.id
  type              = "ingress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [var.hcp_vpc_cidr]
  description       = "Allow UDP gossip traffic from HCP Consul Clients to HCP Cluster."
}

resource "aws_security_group_rule" "hcp_consul_client_allow_outbound" {
  security_group_id = aws_security_group.hcp_consul_client.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow any outbound traffic."
}