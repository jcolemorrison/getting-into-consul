output "consul_server" {
  value       = aws_lb.alb.dns_name
  description = "DNS name of AWS ALB for Consul server"
}

output "web_server" {
	value = aws_lb.alb_web.dns_name
  description = "DNS name of AWS ALB for the fake web service"
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

output "asg_consul_server_name" {
	value = aws_autoscaling_group.consul_server.name
	description = "Name of the Consul Server AutoScaling Group"
}

output "asg_api_name" {
	value = aws_autoscaling_group.consul_client_api.name
	description = "Name of the API AutoScaling Group"
}

output "asg_api_v2_name" {
	value = aws_autoscaling_group.consul_client_api_v2.name
	description = "Name of the API v2 AutoScaling Group"
}

output "asg_web_name" {
	value = aws_autoscaling_group.consul_client_web.name
	description = "Name of the Web AutoScaling Group"
}

output "asg_ig_name" {
	value = aws_autoscaling_group.ingress_gateway.name
	description = "Name of the Ingress Gateway AutoScaling Group"
}

output "aws_region" {
	value = var.aws_default_region
	description = "Region in AWS everything is deployed to"
}

output "main_project_tag" {
	value = var.main_project_tag
	description = "Tag that will be attached to all resources."
}

output "vpc_id" {
	value = aws_vpc.consul.id
	description = "ID of VPC project resources are deployed into."
}

output "vpc_private_subnet_ids" {
	value = aws_subnet.private.*.id
	description = "IDs of the VPC private subnets"
}

output "vpc_public_subnet_ids" {
	value = aws_subnet.public.*.id
	description = "IDs of the VPC public subnets"
}

output "ec2_key_pair_name" {
	value = var.ec2_key_pair_name
	description = "EC2 keypair name"
}

output "bastion_security_group_id" {
	value = aws_security_group.bastion.id
	description = "Bastion Security Group ID"
}

output "consul_server_security_group_id" {
	value = aws_security_group.consul_server.id
	description = "Consul Server Security Group ID"
}

output "consul_client_security_group_id" {
	value = aws_security_group.consul_client.id
	description = "Consul Client Security Group ID"
}

output "allowed_traffic_cidr_blocks_ipv6" {
	value = var.allowed_traffic_cidr_blocks_ipv6
}