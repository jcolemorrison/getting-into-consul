# ASG for the Consul Servers
resource "aws_autoscaling_group" "consul_server" {
	name_prefix = "${var.main_project_tag}-server-asg-"

	launch_template {
    id = aws_launch_template.consul_server.id
    version = aws_launch_template.consul_server.latest_version
  }

	target_group_arns = [aws_lb_target_group.alb_targets.arn]

	desired_capacity = var.server_desired_count
  min_size = var.server_min_count
  max_size = var.server_max_count

	# AKA the subnets to launch resources in 
  vpc_zone_identifier = aws_subnet.private.*.id

  health_check_grace_period = 300
  health_check_type = "EC2"
  termination_policies = ["OldestLaunchTemplate"]
  wait_for_capacity_timeout = 0

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"
  ]

  tags = [
    {
      key = "Name"
      value = "${var.main_project_tag}-server"
      propagate_at_launch = true
    },
    {
      key = "Project"
      value = var.main_project_tag
      propagate_at_launch = true
    }
  ]

  # Allow time for internet access before installing external packages
  depends_on = [aws_nat_gateway.nat]
}

# ASG for the Consul Web Clients
resource "aws_autoscaling_group" "consul_client_web" {
	name_prefix = "${var.main_project_tag}-web-asg-"

	launch_template {
    id = aws_launch_template.consul_client_web.id
    version = aws_launch_template.consul_client_web.latest_version
  }

	target_group_arns = [aws_lb_target_group.alb_targets_web.arn]

	desired_capacity = var.client_web_desired_count
  min_size = var.client_web_min_count
  max_size = var.client_web_max_count

	# AKA the subnets to launch resources in 
  vpc_zone_identifier = aws_subnet.private.*.id

  health_check_grace_period = 300
  health_check_type = "EC2"
  termination_policies = ["OldestLaunchTemplate"]
  wait_for_capacity_timeout = 0

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"
  ]

  tags = [
    {
      key = "Name"
      value = "${var.main_project_tag}-web"
      propagate_at_launch = true
    },
    {
      key = "Project"
      value = var.main_project_tag
      propagate_at_launch = true
    }
  ]

  # Allow time for internet access before installing external packages
  depends_on = [aws_nat_gateway.nat]
}

# ASG for the Consul API Clients
resource "aws_autoscaling_group" "consul_client_api" {
	name_prefix = "${var.main_project_tag}-api-asg-"

	launch_template {
    id = aws_launch_template.consul_client_api.id
    version = aws_launch_template.consul_client_api.latest_version
  }

	desired_capacity = var.client_api_desired_count
  min_size = var.client_api_min_count
  max_size = var.client_api_max_count

	# AKA the subnets to launch resources in 
  vpc_zone_identifier = aws_subnet.private.*.id

  health_check_grace_period = 300
  health_check_type = "EC2"
  termination_policies = ["OldestLaunchTemplate"]
  wait_for_capacity_timeout = 0

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"
  ]

  tags = [
    {
      key = "Name"
      value = "${var.main_project_tag}-api"
      propagate_at_launch = true
    },
    {
      key = "Project"
      value = var.main_project_tag
      propagate_at_launch = true
    }
  ]

  # Allow time for internet access before installing external packages
  depends_on = [aws_nat_gateway.nat]
}

# ASG for the Consul API v2 Clients - unused for gateways
# resource "aws_autoscaling_group" "consul_client_api_v2" {
# 	name_prefix = "${var.main_project_tag}-api-v2-asg-"

# 	launch_template {
#     id = aws_launch_template.consul_client_api_v2.id
#     version = aws_launch_template.consul_client_api_v2.latest_version
#   }

# 	desired_capacity = var.client_api_v2_desired_count
#   min_size = var.client_api_v2_min_count
#   max_size = var.client_api_v2_max_count

# 	# AKA the subnets to launch resources in 
#   vpc_zone_identifier = aws_subnet.private.*.id

#   health_check_grace_period = 300
#   health_check_type = "EC2"
#   termination_policies = ["OldestLaunchTemplate"]
#   wait_for_capacity_timeout = 0

#   enabled_metrics = [
#     "GroupDesiredCapacity",
#     "GroupInServiceCapacity",
#     "GroupPendingCapacity",
#     "GroupMinSize",
#     "GroupMaxSize",
#     "GroupInServiceInstances",
#     "GroupPendingInstances",
#     "GroupStandbyInstances",
#     "GroupStandbyCapacity",
#     "GroupTerminatingCapacity",
#     "GroupTerminatingInstances",
#     "GroupTotalCapacity",
#     "GroupTotalInstances"
#   ]

#   tags = [
#     {
#       key = "Name"
#       value = "${var.main_project_tag}-api-v2"
#       propagate_at_launch = true
#     },
#     {
#       key = "Project"
#       value = var.main_project_tag
#       propagate_at_launch = true
#     }
#   ]

#   # Allow time for internet access before installing external packages
#   depends_on = [aws_nat_gateway.nat]
# }

