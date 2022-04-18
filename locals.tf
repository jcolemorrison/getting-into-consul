locals {
  public_cidr_blocks = [for i in range(var.vpc_public_subnet_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_cidr_blocks = [for i in range(var.vpc_private_subnet_count) : cidrsubnet(var.vpc_cidr, 4, i+var.vpc_public_subnet_count)]
  server_private_ips = [for i in local.private_cidr_blocks : cidrhost(i, 250)]
  public_cidr_blocks_dc2 = [for i in range(var.vpc_public_subnet_count_dc2) : cidrsubnet(var.vpc_cidr_dc2, 4, i)]
  private_cidr_blocks_dc2 = [for i in range(var.vpc_private_subnet_count_dc2) : cidrsubnet(var.vpc_cidr_dc2, 4, i+var.vpc_public_subnet_count_dc2)]
  server_private_ips_dc2 = [for i in local.private_cidr_blocks_dc2 : cidrhost(i, 250)]
}