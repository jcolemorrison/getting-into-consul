output "consul_server" {
  value       = aws_lb.alb.dns_name
  description = "DNS name of AWS ALB for Consul server"
}

output "bastion_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP address of bastion"
}

output "vault_addr" {
  value       = module.hcp.hcp_vault_private_endpoint
  description = "Private endpoint of HCP Vault cluster"
}

output "vault_public_addr" {
  value       = module.hcp.hcp_vault_public_endpoint
  description = "Public endpoint of HCP Vault cluster"
}

output "consul_token" {
  value       = random_uuid.consul_bootstrap_token.result
  description = "Consul management token"
  sensitive   = true
}