output "consul_server" {
  value       = aws_lb.alb.dns_name
  description = "DNS name of AWS ALB for Consul server"
}

output "bastion_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP address of bastion"
}