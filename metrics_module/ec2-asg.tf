resource "aws_autoscaling_group" "metrics" {
	name_prefix = "${var.main_project_tag}-metrics-asg-"

	launch_template {
    id = aws_launch_template.metrics.id
    version = aws_launch_template.metrics.latest_version
  }

	target_group_arns = [aws_lb_target_group.alb_targets_metrics.arn]

	desired_capacity = var.client_metrics_desired_count
  min_size = var.client_metrics_min_count
  max_size = var.client_metrics_max_count

	# AKA the subnets to launch resources in 
  vpc_zone_identifier = var.vpc_private_subnet_ids

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
      value = "${var.main_project_tag}-metrics"
      propagate_at_launch = true
    },
    {
      key = "Project"
      value = var.main_project_tag
      propagate_at_launch = true
    }
  ]
}