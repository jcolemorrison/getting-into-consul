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


data "aws_instances" "consul_servers" {
  instance_tags = {
    Name = "${var.main_project_tag}-server"
  }

  instance_state_names = ["running"]
}

data "aws_instances" "consul_clients_api" {
  instance_tags = {
    Name = "${var.main_project_tag}-api"
  }

  instance_state_names = ["running"]
}

data "aws_instances" "consul_clients_web" {
  instance_tags = {
    Name = "${var.main_project_tag}-web"
  }

  instance_state_names = ["running"]
}

output "consul_server_ips" {
  value       = data.aws_instances.consul_servers.private_ips
  description = "list of Consul server private IP addresses"
}

output "consul_client_api_ips" {
  value       = "consul acl token create -node-identity=\"ip-${replace(data.aws_instances.consul_clients_api.private_ips.0, ".", "-")}:dc1\""
  description = "ACL command for creating a token for Consul client on API service node"
}

output "consul_client_web_ips" {
  value       = "consul acl token create -node-identity=\"ip-${replace(data.aws_instances.consul_clients_web.private_ips.0, ".", "-")}:dc1\""
  description = "ACL command for creating a token for Consul client on Web service node"
}