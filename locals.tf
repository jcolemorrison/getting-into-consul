locals {
  public_cidr_blocks = [for i in range(var.vpc_public_subnet_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_cidr_blocks = [for i in range(var.vpc_private_subnet_count) : cidrsubnet(var.vpc_cidr, 4, i+var.vpc_public_subnet_count)]
  server_private_ips = [for i in local.private_cidr_blocks : cidrhost(i, 250)]
  # TODO - assumes we'll never want more than one consul server per availability zone...
  # Which means we could just tie the server count to the AZs or vice versa.
  server_private_hostnames = [for i in local.server_private_ips : join("-", ["ip", replace(i, ".", "-")])]
  public_cidr_blocks_dc2 = [for i in range(var.vpc_public_subnet_count_dc2) : cidrsubnet(var.vpc_cidr_dc2, 4, i)]
  private_cidr_blocks_dc2 = [for i in range(var.vpc_private_subnet_count_dc2) : cidrsubnet(var.vpc_cidr_dc2, 4, i+var.vpc_public_subnet_count_dc2)]
  server_private_ips_dc2 = [for i in local.private_cidr_blocks_dc2 : cidrhost(i, 250)]
  server_private_hostnames_dc2 = [for i in local.server_private_ips_dc2 : join("-", ["ip", replace(i, ".", "-")])]
}