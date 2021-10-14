locals {
  hcp_region      = var.hcp_region == "" ? var.aws_default_region : var.hcp_region
  route_table_ids = [aws_route_table.private.id, aws_route_table.public.id]
}

module "hcp" {
  source                    = "joatmon08/hcp/aws"
  version                   = "2.0.1"
  hvn_cidr_block            = var.hcp_cidr_block
  hvn_name                  = var.main_project_tag
  hvn_region                = local.hcp_region
  number_of_route_table_ids = length(local.route_table_ids)
  route_table_ids           = local.route_table_ids
  vpc_cidr_block            = aws_vpc.consul.cidr_block
  vpc_id                    = aws_vpc.consul.id
  vpc_owner_id              = aws_vpc.consul.owner_id
  hcp_vault_name            = var.main_project_tag
  hcp_vault_public_endpoint = var.hcp_vault_public_endpoint
  tags = merge(
    { "Name" = "${var.main_project_tag}-hcp" },
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )
}
