# General Variables
variable "main_project_tag" {
  description = "Tag that will be attached to all resources."
  type        = string
  default     = "getting-into-consul"
}

variable "aws_default_region" {
  description = "The default region that all resources will be deployed into."
  type        = string
  default     = "us-east-1"
}

# EC2 Variables
variable "ami_id" {
  description = "AMI ID to be used on all AWS EC2 Instances."
  type        = string
  default     = "ami-0747bdcabd34c712a" # Latest Ubuntu 18.04 LTS (HVM), SSD Volume Type
}

variable "use_latest_ami" {
  description = "Whether or not to use the hardcoded ami_id value or to grab the latest value from SSM parameter store."
  type = bool
  default = true
}

variable "ec2_key_pair_name" {
  description = "An existing EC2 key pair used to access the bastion server."
  type        = string
}

## Consul Metrics Clients
variable "client_metrics_desired_count" {
  description = "The desired number of consul metrics clients."
  type        = number
  default     = 1
}

variable "client_metrics_min_count" {
  description = "The minimum number of consul metrics clients."
  type        = number
  default     = 1
}

variable "client_metrics_max_count" {
  description = "The maximum number of consul metrics clients."
  type        = number
  default     = 1
}

# Metrics VPC
variable "vpc_id" {
  type = string
  description = "VPC ID the metrics resources are deployed into."
}

variable "vpc_private_subnet_ids" {
  description = "A list of private subnet IDs for the metrics autoscaling group to deploy into."
  type = list(string)
}

variable "vpc_public_subnet_ids" {
  description = "A list of public subnet IDs for the metrics autoscaling group to deploy into."
  type = list(string)
}

# Metrics Source Security Groups
variable "bastion_security_group_id" {
  type = string
  description = "Security Group ID for the Bastion allowed access into the Metrics server"
}

variable "consul_server_security_group_id" {
  type = string
  description = "Security Group ID of the Consul Server to allow access for the Metrics server"
}

variable "consul_client_security_group_id" {
  type = string
  description = "Security Group ID of the Consul Clients to allow access for the Metrics server"
}

# Allowed Traffic into the Metrics Server
variable "allowed_traffic_cidr_blocks" {
  description = "List of CIDR blocks allowed to send requests to your Metrics server endpoint.  Defaults to EVERYWHERE."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_traffic_cidr_blocks_ipv6" {
  description = "List of IPv6 CIDR blocks allowed to send requests to your Metrics server endpoint.  Defaults to EVERYWHERE."
  type        = list(string)
  default     = ["::/0"]
}

# Consul Server Values
variable "consul_server_ip" {
  type = string
  description = "consul server IP."
}

variable "consul_token" {
  type = string
  description = "ACL token for the consul server."
  sensitive = true
}