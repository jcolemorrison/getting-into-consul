## Application Load Balancer - Consul Server dc2
resource "aws_lb" "alb_dc2" {
  name_prefix        = "csul2-" # 6 character length
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_dc2.id]
  subnets            = aws_subnet.dc2_public.*.id
  idle_timeout       = 60
  ip_address_type    = "dualstack"

  tags = merge(
    { "Name" = "${var.main_project_tag}-alb-dc2" },
    { "Project" = var.main_project_tag }
  )
}

## Target Group
resource "aws_lb_target_group" "alb_targets_dc2" {
  name_prefix          = "csul2-"
  port                 = 8500
  protocol             = "HTTP"
  vpc_id               = aws_vpc.dc2.id
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
    { "Name" = "${var.main_project_tag}-tg-dc2" },
    { "Project" = var.main_project_tag }
  )
}

## Default HTTP listener
resource "aws_lb_listener" "alb_http_dc2" {
  load_balancer_arn = aws_lb.alb_dc2.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_targets_dc2.arn
  }
}