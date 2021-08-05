# General Variables
variable "main_project_tag" {
  description = "Tag that will be attached to all resources."
  type        = string
  default     = "consul-hardway"
}

# VPC Variables
variable "vpc_cidr" {
  description = "Cidr block for the VPC.  Using a /16 or /20 Subnet Mask is recommended."
  type        = string
  default     = "10.255.0.0/20"
}

variable "vpc_instance_tenancy" {
  description = "Tenancy for instances launched into the VPC."
  type        = string
  default     = "default"
}

variable "vpc_tags" {
  description = "Additional tags to add to the VPC and its resources."
  type        = map(string)
  default     = {}
}

variable "vpc_public_subnet_count" {
  description = "The number of public subnets to create.  Cannot exceed the number of AZs in your selected region.  2 is more than enough."
  type        = number
  default     = 2
}

variable "vpc_private_subnet_count" {
  description = "The number of private subnets to create.  Cannot exceed the number of AZs in your selected region."
  type        = number
  default     = 2
}