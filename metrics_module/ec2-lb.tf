## Application Load Balancer - Metrics
resource "aws_lb" "alb_metrics" {
  name_prefix        = "csulm-" # 6 character length
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = var.vpc_public_subnet_ids
  idle_timeout       = 60
  ip_address_type    = "dualstack"

  tags = merge(
    { "Name" = "${var.main_project_tag}-alb-metrics" },
    { "Project" = var.main_project_tag }
  )
}

## Target Group
resource "aws_lb_target_group" "alb_targets_metrics" {
  name_prefix          = "csulm-"
  port                 = 9090
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
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
    { "Name" = "${var.main_project_tag}-tg-metrics" },
    { "Project" = var.main_project_tag }
  )
}

## Default HTTP listener
resource "aws_lb_listener" "alb_http_metrics" {
  load_balancer_arn = aws_lb.alb_metrics.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_targets_metrics.arn
  }
}
