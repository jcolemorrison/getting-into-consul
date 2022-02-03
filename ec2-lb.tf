## Application Load Balancer - Consul Server
resource "aws_lb" "alb" {
  name_prefix        = "csul-" # 6 character length
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = aws_subnet.public.*.id
  idle_timeout       = 60
  ip_address_type    = "dualstack"

  tags = merge(
    { "Name" = "${var.main_project_tag}-alb" },
    { "Project" = var.main_project_tag }
  )
}

## Target Group
resource "aws_lb_target_group" "alb_targets" {
  name_prefix          = "csul-"
  port                 = 8500
  protocol             = "HTTP"
  vpc_id               = aws_vpc.consul.id
  deregistration_delay = 30
  target_type          = "instance"

  # https://www.consul.io/api-docs/health
  health_check {
    enabled             = true
    interval            = 10
    path                = "/v1/status/leader" // the consul API health port?
    protocol            = "HTTP"              // switch to HTTPS?
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-tg" },
    { "Project" = var.main_project_tag }
  )
}

## Default HTTP listener
resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_targets.arn
  }
}

## Application Load Balancer - Consul Web Client
resource "aws_lb" "alb_web" {
  name_prefix        = "csulw-" # 6 character length
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = aws_subnet.public.*.id
  idle_timeout       = 60
  ip_address_type    = "dualstack"

  tags = merge(
    { "Name" = "${var.main_project_tag}-alb-web" },
    { "Project" = var.main_project_tag }
  )
}

## Target Group
resource "aws_lb_target_group" "alb_targets_web" {
  name_prefix          = "csulw-"
  port                 = 9090
  protocol             = "HTTP"
  vpc_id               = aws_vpc.consul.id
  deregistration_delay = 30
  target_type          = "instance"

  # https://www.consul.io/api-docs/health
  health_check {
    enabled             = true
    interval            = 10
    path                = "/health" // the consul API health port?
    protocol            = "HTTP"    // switch to HTTPS?
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-tg-web" },
    { "Project" = var.main_project_tag }
  )
}

## Default HTTP listener
resource "aws_lb_listener" "alb_http_web" {
  load_balancer_arn = aws_lb.alb_web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_targets_web.arn
  }
}

## Application Load Balancer - Ingress Gateway
resource "aws_lb" "alb_ingress_gateway" {
  name_prefix        = "csuli-" # 6 character length
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ingress_gateway_load_balancer.id]
  subnets            = aws_subnet.public.*.id
  idle_timeout       = 60
  ip_address_type    = "dualstack"

  tags = merge(
    { "Name" = "${var.main_project_tag}-alb-ig" },
    { "Project" = var.main_project_tag }
  )
}

## Target Group
resource "aws_lb_target_group" "alb_targets_ingress_gateway" {
  name_prefix          = "csuli-"
  port                 = 9090
  protocol             = "HTTP"
  vpc_id               = aws_vpc.consul.id
  deregistration_delay = 30
  target_type          = "instance"

  # https://www.consul.io/api-docs/health
  health_check {
    enabled             = true
    interval            = 10
    path                = "/health" // the consul API health port?
    protocol            = "HTTP"    // switch to HTTPS?
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-tg-ig" },
    { "Project" = var.main_project_tag }
  )
}

## Default HTTP listener
resource "aws_lb_listener" "alb_http_ig" {
  load_balancer_arn = aws_lb.alb_ingress_gateway.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_targets_ingress_gateway.arn
  }
}

## Application Load Balancer - Terminating Gateway
resource "aws_lb" "alb_terminating_gateway" {
  name_prefix        = "csult-" # 6 character length
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terminating_gateway_load_balancer.id]
  subnets            = aws_subnet.private.*.id
  idle_timeout       = 60
  internal = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-alb-tm" },
    { "Project" = var.main_project_tag }
  )
}

## Target Group
resource "aws_lb_target_group" "alb_targets_terminating_gateway" {
  name_prefix          = "csult-"
  port                 = 9090
  protocol             = "HTTP"
  vpc_id               = aws_vpc.consul.id
  deregistration_delay = 30
  target_type          = "instance"

  # https://www.consul.io/api-docs/health
  health_check {
    enabled             = true
    interval            = 10
    path                = "/health" // the consul API health port?
    protocol            = "HTTP"    // switch to HTTPS?
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-tg-tm" },
    { "Project" = var.main_project_tag }
  )
}

## Default HTTP listener
resource "aws_lb_listener" "alb_http_tm" {
  load_balancer_arn = aws_lb.alb_terminating_gateway.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_targets_terminating_gateway.arn
  }
}
