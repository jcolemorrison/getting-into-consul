variable "services" {
  description = "Consul services monitored by Consul-Terraform-Sync"
  type = map(
    object({
      id        = string
      name      = string
      kind      = string
      address   = string
      port      = number
      meta      = map(string)
      tags      = list(string)
      namespace = string
      status    = string

      node                  = string
      node_id               = string
      node_address          = string
      node_datacenter       = string
      node_tagged_addresses = map(string)
      node_meta             = map(string)

      cts_user_defined_meta = map(string)
    })
  )
}

variable "name" {
  type        = string
  description = "Name of resources for this CTS module"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to attach to load balancer"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for application target group"
}

variable "application_security_group_id" {
  type        = string
  description = "Security Group ID for application to allow load balancer access"
}

variable "tags" {
  type        = map(string)
  description = "List of tags for all resources"
  default = {
    "Purpose" = "getting-into-consul"
    "Module"  = "cts_module"
  }
}

variable "load_balancer_port" {
  type        = number
  description = "Load balancer port for clients to access"
  default     = 80
}

variable "load_balancer_protocol" {
  type        = string
  description = "Load balancer protocol for clients to access"
  default     = "HTTP"
}

variable "load_balancer_allow_cidr_blocks" {
  type        = list(string)
  description = "Load balancer CIDR blocks to allow"
  default     = ["0.0.0.0/0"]
}

locals {
  application_port              = 9090
  application_health_check_path = ""
  application_name              = "example"
  ip_addresses                  = toset([])
}