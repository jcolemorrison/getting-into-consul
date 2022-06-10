resource "aws_security_group" "alb" {
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow traffic to load balancer"
    from_port   = var.load_balancer_port
    to_port     = var.load_balancer_port
    protocol    = "tcp"
    cidr_blocks = var.load_balancer_allow_cidr_blocks
  }

  vpc_id = var.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "lb_to_app" {
  type                     = "ingress"
  from_port                = local.application_port
  to_port                  = local.application_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = var.application_security_group_id
}

resource "aws_lb" "cts" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_lb_listener" "cts" {
  load_balancer_arn = aws_lb.cts.arn
  port              = var.load_balancer_port
  protocol          = var.load_balancer_protocol

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

resource "aws_lb_target_group" "app" {
  name        = local.application_name
  port        = local.application_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path    = local.application_health_check_path
  }
}

resource "aws_lb_target_group_attachment" "app" {
  for_each          = local.ip_addresses
  target_group_arn  = aws_lb_target_group.app.arn
  target_id         = each.value
  port              = local.application_port
  availability_zone = "all"
}

resource "aws_lb_listener_rule" "app" {
  listener_arn = aws_lb_listener.cts.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["/${local.application_name}/*"]
    }
  }
}