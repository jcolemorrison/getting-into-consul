## Load Balancer SG
resource "aws_security_group" "load_balancer" {
  name_prefix = "${var.main_project_tag}-metrics-alb-sg"
  description = "Firewall for the application load balancer fronting the metrics server."
  vpc_id      = var.vpc_id
  tags = merge(
    { "Name" = "${var.main_project_tag}-metrics-alb-sg" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_security_group_rule" "load_balancer_allow_80" {
  security_group_id = aws_security_group.load_balancer.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = var.allowed_traffic_cidr_blocks
  ipv6_cidr_blocks  = length(var.allowed_traffic_cidr_blocks_ipv6) > 0 ? var.allowed_traffic_cidr_blocks_ipv6 : null
  description       = "Allow HTTP traffic."
}

resource "aws_security_group_rule" "load_balancer_allow_443" {
  security_group_id = aws_security_group.load_balancer.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = var.allowed_traffic_cidr_blocks
  ipv6_cidr_blocks  = length(var.allowed_traffic_cidr_blocks_ipv6) > 0 ? var.allowed_traffic_cidr_blocks_ipv6 : null
  description       = "Allow HTTPS traffic."
}

resource "aws_security_group_rule" "load_balancer_allow_outbound" {
  security_group_id = aws_security_group.load_balancer.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = length(var.allowed_traffic_cidr_blocks_ipv6) > 0 ? ["::/0"] : null
  description       = "Allow any outbound traffic."
}

## Metrics SG
resource "aws_security_group" "metrics" {
  name_prefix = "${var.main_project_tag}-metrics-sg"
  description = "Firewall for the metrics instance"
  vpc_id      = var.vpc_id
  tags = merge(
    { "Name" = "${var.main_project_tag}-metrics-sg" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_security_group_rule" "metrics_allow_22" {
  security_group_id = aws_security_group.metrics.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  source_security_group_id = var.bastion_security_group_id
  description       = "Allow SSH traffic from consul bastion."
}

resource "aws_security_group_rule" "metrics_allow_lb_9090" {
  security_group_id        = aws_security_group.metrics.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9090
  to_port                  = 9090
  source_security_group_id = aws_security_group.load_balancer.id
  description              = "Allow traffic from Load Balancer to Metrics Clients for Prometheus."
}

resource "aws_security_group_rule" "metrics_allow_outbound" {
  security_group_id = aws_security_group.metrics.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow any outbound traffic."
}

# Consul Resource Access - the Metrics server needs to be cleared to access consul server and services.
# The security group ID of these is passed into this module and additional listeners are attached.

resource "aws_security_group_rule" "consul_server_allow_metrics_8500" {
  security_group_id        = var.consul_server_security_group_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8500
  to_port                  = 8500
  source_security_group_id = aws_security_group.metrics.id
  description              = "Allow HTTP traffic from Metrics Client to Consul Server for Prometheus."
}


resource "aws_security_group_rule" "consul_client_allow_9102" {
  security_group_id        = var.consul_client_security_group_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9102
  to_port                  = 9102
  source_security_group_id = aws_security_group.metrics.id
  description              = "Allow traffic to the Consul Clients from the Metrics Client for Prometheus."
}