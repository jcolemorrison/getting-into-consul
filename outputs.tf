output "consul_server" {
  value       = aws_lb.alb.dns_name
  description = "DNS name of AWS ALB for Consul server"
}

output "bastion_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP address of bastion"
}

output "consul_token" {
  value       = random_uuid.consul_bootstrap_token.result
  description = "Consul management token"
  sensitive   = true
}

output "asg_api_name" {
	value = aws_autoscaling_group.consul_client_api.name
	description = "Name of the API AutoScaling Group"
}

output "asg_web_name" {
	value = aws_autoscaling_group.consul_client_web.name
	description = "Name of the Web AutoScaling Group"
}

output "aws_region" {
	value = var.aws_default_region
	description = "Region in AWS everything is deployed to"
}