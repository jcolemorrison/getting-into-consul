## Bastion SG
resource "aws_security_group" "bastion_dc2" {
  name_prefix = "${var.main_project_tag}-bastion-sg-dc2"
  description = "Firewall for the bastion dc2 instance"
  vpc_id      = aws_vpc.dc2.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-bastion-sg-dc2" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_security_group_rule" "bastion_dc2_allow_22" {
  security_group_id = aws_security_group.bastion_dc2.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = var.allowed_bastion_cidr_blocks
  ipv6_cidr_blocks  = length(var.allowed_bastion_cidr_blocks_ipv6) > 0 ? var.allowed_bastion_cidr_blocks_ipv6 : null
  description       = "Allow SSH traffic."
}

resource "aws_security_group_rule" "bastion_dc2_allow_outbound" {
  security_group_id = aws_security_group.bastion_dc2.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = length(var.allowed_bastion_cidr_blocks_ipv6) > 0 ? ["::/0"] : null
  description       = "Allow any outbound traffic."
}

## Load Balancer SG
resource "aws_security_group" "load_balancer_dc2" {
  name_prefix = "${var.main_project_tag}-alb-sg-dc2"
  description = "Firewall for the application load balancer (dc2) fronting the consul server."
  vpc_id      = aws_vpc.dc2.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-alb-sg-dc2" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_security_group_rule" "load_balancer_dc2_allow_80" {
  security_group_id = aws_security_group.load_balancer_dc2.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = var.allowed_traffic_cidr_blocks
  ipv6_cidr_blocks  = length(var.allowed_traffic_cidr_blocks_ipv6) > 0 ? var.allowed_traffic_cidr_blocks_ipv6 : null
  description       = "Allow HTTP traffic."
}

resource "aws_security_group_rule" "load_balancer_dc2_allow_443" {
  security_group_id = aws_security_group.load_balancer_dc2.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = var.allowed_traffic_cidr_blocks
  ipv6_cidr_blocks  = length(var.allowed_traffic_cidr_blocks_ipv6) > 0 ? var.allowed_traffic_cidr_blocks_ipv6 : null
  description       = "Allow HTTPS traffic."
}

resource "aws_security_group_rule" "load_balancer_dc2_allow_outbound" {
  security_group_id = aws_security_group.load_balancer_dc2.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = length(var.allowed_traffic_cidr_blocks_ipv6) > 0 ? ["::/0"] : null
  description       = "Allow any outbound traffic."
}

## Consul Server Instance SG
resource "aws_security_group" "consul_server_dc2" {
  name_prefix = "${var.main_project_tag}-consul-server-sg-dc2"
  description = "Firewall for the consul server in dc2."
  vpc_id      = aws_vpc.dc2.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-consul-server-sg-dc2" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_security_group_rule" "consul_server_dc2_allow_8500" {
  security_group_id        = aws_security_group.consul_server_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8500
  to_port                  = 8500
  source_security_group_id = aws_security_group.load_balancer_dc2.id
  description              = "Allow HTTP traffic from Load Balancer in Dc2."
}

resource "aws_security_group_rule" "consul_server_dc2_allow_client_8500" {
  security_group_id        = aws_security_group.consul_server_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8500
  to_port                  = 8500
  source_security_group_id = aws_security_group.consul_client_dc2.id
  description              = "Allow HTTP traffic from Consul Client in DC2."
}

resource "aws_security_group_rule" "consul_server_dc2_allow_client_8301" {
  security_group_id        = aws_security_group.consul_server_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.consul_client_dc2.id
  description              = "Allow LAN gossip traffic from Consul Client to Server in DC2.  For managing cluster membership for distributed health check of the agents."
}

resource "aws_security_group_rule" "consul_server_dc2_allow_client_8300" {
  security_group_id        = aws_security_group.consul_server_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8300
  to_port                  = 8300
  source_security_group_id = aws_security_group.consul_client_dc2.id
  description              = "Allow RPC traffic from Consul Client to Server in DC2.  For client and server agents to send and receive data stored in Consul."
}

resource "aws_security_group_rule" "consul_server_allow_mesh_gateway_dc2_8500" {
  security_group_id        = aws_security_group.consul_server_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8500
  to_port                  = 8500
  source_security_group_id = aws_security_group.mesh_gateway_dc2.id
  description              = "Allow HTTP traffic from Consul mesh gateway."
}

resource "aws_security_group_rule" "consul_server_allow_mesh_gateway_dc2_8301" {
  security_group_id        = aws_security_group.consul_server_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.mesh_gateway_dc2.id
  description              = "Allow LAN gossip traffic from Consul Mesh Gateway to Server.  For managing cluster membership for distributed health check of the agents."
}

resource "aws_security_group_rule" "consul_server_allow_mesh_gateway_dc2_8300" {
  security_group_id        = aws_security_group.consul_server_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8300
  to_port                  = 8300
  source_security_group_id = aws_security_group.mesh_gateway_dc2.id
  description              = "Allow RPC traffic from Consul Mesh Gateway to Server.  For mesh gateway and server agents to send and receive data stored in Consul."
}

resource "aws_security_group_rule" "consul_server_dc2_allow_server_8301" {
  security_group_id        = aws_security_group.consul_server_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.consul_server_dc2.id
  description              = "Allow LAN gossip traffic from Consul Server to Server in DC2.  For managing cluster membership for distributed health check of the agents."
}

resource "aws_security_group_rule" "consul_server_dc2_allow_server_8300" {
  security_group_id        = aws_security_group.consul_server_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8300
  to_port                  = 8300
  source_security_group_id = aws_security_group.consul_server_dc2.id
  description              = "Allow RPC traffic from Consul Server to Server in DC2.  For client and server agents to send and receive data stored in Consul."
}

resource "aws_security_group_rule" "consul_server_dc2_allow_22_bastion" {
  security_group_id        = aws_security_group.consul_server_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = aws_security_group.bastion_dc2.id
  description              = "Allow SSH traffic from consul bastion in DC2."
}

resource "aws_security_group_rule" "consul_server_dc2_allow_outbound" {
  security_group_id = aws_security_group.consul_server_dc2.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow any outbound traffic."
}

## Consul Client Instance SG
resource "aws_security_group" "consul_client_dc2" {
  name_prefix = "${var.main_project_tag}-consul-client-sg-dc2"
  description = "Firewall for the consul client in dc2."
  vpc_id      = aws_vpc.dc2.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-consul-client-sg-dc2" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_security_group_rule" "consul_client_dc2_allow_8500" {
  security_group_id        = aws_security_group.consul_client_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8500
  to_port                  = 8500
  source_security_group_id = aws_security_group.load_balancer_dc2.id
  description              = "Allow HTTP traffic from Load Balancer in dc2."
}

resource "aws_security_group_rule" "consul_client_dc2_allow_lb_9090" {
  security_group_id        = aws_security_group.consul_client_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9090
  to_port                  = 9090
  source_security_group_id = aws_security_group.load_balancer_dc2.id
  description              = "Allow traffic from Load Balancer to Consul Clients in DC2 for Fake Service."
}

resource "aws_security_group_rule" "consul_client_dc2_allow_9090" {
  security_group_id        = aws_security_group.consul_client_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9090
  to_port                  = 9090
  source_security_group_id = aws_security_group.consul_client_dc2.id
  description              = "Allow traffic from Consul Clients for Fake Service in DC2."
}

resource "aws_security_group_rule" "consul_client_dc2_allow_20000" {
  security_group_id        = aws_security_group.consul_client_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 20000
  to_port                  = 20000
  source_security_group_id = aws_security_group.consul_client_dc2.id
  description              = "Allow traffic from Consul Clients for Fake Service via Envoy Proxy in DC2."
}

resource "aws_security_group_rule" "consul_client_dc2_allow_22_bastion" {
  security_group_id        = aws_security_group.consul_client_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = aws_security_group.bastion_dc2.id
  description              = "Allow SSH traffic from consul bastion in dc2."
}

resource "aws_security_group_rule" "consul_client_dc2_allow_outbound" {
  security_group_id = aws_security_group.consul_client_dc2.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow any outbound traffic."
}

# Mesh Gateway DC2 Security Group
resource "aws_security_group" "mesh_gateway_dc2" {
  name_prefix = "${var.main_project_tag}-mesh-gateway-sg-dc2"
  description = "Firewall for the mesh gateway in dc2."
  vpc_id      = aws_vpc.dc2.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-mesh-gateways-sg-dc2" },
    { "Project" = var.main_project_tag }
  )
}

# Peering connections require the cidr block since security group ID's won't carry across peered vpcs
# NOTE FOR PART 11: This should enable inbound traffic for both:
# - mesh gateway in DC1
resource "aws_security_group_rule" "mesh_gateway_dc2_allow_dc2_8300" {
  security_group_id = aws_security_group.mesh_gateway_dc2.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8300
  to_port           = 8300
  # TODO: constrain this to the specific CIDR of the other mesh gateway
  cidr_blocks       = [var.vpc_cidr]
  description       = "TODO"
}

resource "aws_security_group_rule" "mesh_gateway_dc2_allow_dc2_8443" {
  security_group_id = aws_security_group.mesh_gateway_dc2.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8443
  to_port           = 8443
  # TODO: constrain this to the specific CIDR of the other mesh gateway
  cidr_blocks       = [var.vpc_cidr]
  description       = "TODO"
}

resource "aws_security_group_rule" "mesh_gateway_dc2_allow_22_bastion" {
  security_group_id        = aws_security_group.mesh_gateway_dc2.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = aws_security_group.bastion_dc2.id
  description              = "Allow SSH traffic from consul bastion."
}

resource "aws_security_group_rule" "mesh_gateway_dc2_allow_outbound" {
  security_group_id = aws_security_group.mesh_gateway_dc2.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow any outbound traffic."
}