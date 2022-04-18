# Main VPC resource
resource "aws_vpc" "dc2" {
  cidr_block                       = var.vpc_cidr_dc2
  instance_tenancy                 = var.vpc_instance_tenancy_dc2
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-dc2-vpc" },
    { "Project" = var.main_project_tag },
    var.vpc_tags_dc2
  )
}

## Internet Gateway
resource "aws_internet_gateway" "dc2_igw" {
  vpc_id = aws_vpc.dc2.id

  tags = merge(
    { "Name" = "${var.main_project_tag}-dc2-igw" },
    { "Project" = var.main_project_tag },
    var.vpc_tags_dc2
  )
}

## Egress Only Gateway (IPv6)
resource "aws_egress_only_internet_gateway" "dc2_eigw" {
  vpc_id = aws_vpc.dc2.id
}


## The NAT Elastic IP
resource "aws_eip" "dc2_nat" {
  vpc = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-dc2-nat-eip" },
    { "Project" = var.main_project_tag },
    var.vpc_tags_dc2
  )

  depends_on = [aws_internet_gateway.dc2_igw]
}

## The NAT Gateway
resource "aws_nat_gateway" "dc2_nat" {
  allocation_id = aws_eip.dc2_nat.id
  subnet_id     = aws_subnet.dc2_public.0.id

  tags = merge(
    { "Name" = "${var.main_project_tag}-dc2-nat" },
    { "Project" = var.main_project_tag },
    var.vpc_tags_dc2
  )

  depends_on = [
    aws_internet_gateway.dc2_igw,
    aws_eip.dc2_nat
  ]
}

## Public Route Table
resource "aws_route_table" "dc2_public" {
  vpc_id = aws_vpc.dc2.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-dc2-public-rtb" },
    { "Project" = var.main_project_tag },
    var.vpc_tags_dc2
  )
}

## Public routes
resource "aws_route" "dc2_public_internet_access" {
  route_table_id         = aws_route_table.dc2_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dc2_igw.id
}

## Private Route Table
resource "aws_route_table" "dc2_private" {
  vpc_id = aws_vpc.dc2.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-dc2-private-rtb" },
    { "Project" = var.main_project_tag },
    var.vpc_tags_dc2
  )
}

## Private Routes
resource "aws_route" "dc2_private_internet_access" {
  route_table_id         = aws_route_table.dc2_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.dc2_nat.id
}

resource "aws_route" "dc2_private_internet_access_ipv6" {
  route_table_id              = aws_route_table.dc2_private.id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.dc2_eigw.id
}

## Public Subnets
resource "aws_subnet" "dc2_public" {
  count = var.vpc_public_subnet_count_dc2

  vpc_id                  = aws_vpc.dc2.id
  cidr_block              = local.public_cidr_blocks_dc2[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  ipv6_cidr_block                 = cidrsubnet(aws_vpc.dc2.ipv6_cidr_block, 8, count.index)
  assign_ipv6_address_on_creation = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-dc2-public-${data.aws_availability_zones.available.names[count.index]}" },
    { "Project" = var.main_project_tag },
    var.vpc_tags_dc2
  )
}

## Private Subnets
resource "aws_subnet" "dc2_private" {
  count = var.vpc_private_subnet_count_dc2

  vpc_id = aws_vpc.dc2.id

  // Increment the netnum by the number of public subnets to avoid overlap
  cidr_block        = local.private_cidr_blocks_dc2[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    { "Name" = "${var.main_project_tag}-dc2-private-${data.aws_availability_zones.available.names[count.index]}" },
    { "Project" = var.main_project_tag },
    var.vpc_tags_dc2
  )
}

## Public Subnet Route Associations
resource "aws_route_table_association" "dc2_public" {
  count = var.vpc_public_subnet_count_dc2

  subnet_id      = element(aws_subnet.dc2_public.*.id, count.index)
  route_table_id = aws_route_table.dc2_public.id
}

## Private Subnet Route Associations
resource "aws_route_table_association" "dc2_private" {
  count = var.vpc_private_subnet_count_dc2

  subnet_id      = element(aws_subnet.dc2_private.*.id, count.index)
  route_table_id = aws_route_table.dc2_private.id
}
