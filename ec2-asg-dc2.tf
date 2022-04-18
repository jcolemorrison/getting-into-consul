# ASG for the Consul API DC2 Clients
resource "aws_autoscaling_group" "consul_client_api_dc2" {
	name_prefix = "${var.main_project_tag}-api-asg-dc2-"

	launch_template {
    id = aws_launch_template.consul_client_api_dc2.id
    version = aws_launch_template.consul_client_api_dc2.latest_version
  }

	desired_capacity = var.client_api_desired_count_dc2
  min_size = var.client_api_min_count_dc2
  max_size = var.client_api_max_count_dc2

	# AKA the subnets to launch resources in 
  vpc_zone_identifier = aws_subnet.dc2_private.*.id

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
      value = "${var.main_project_tag}-api-dc2"
      propagate_at_launch = true
    },
    {
      key = "Project"
      value = var.main_project_tag
      propagate_at_launch = true
    }
  ]

  # Allow time for internet access before installing external packages
  depends_on = [aws_nat_gateway.dc2_nat]
}
