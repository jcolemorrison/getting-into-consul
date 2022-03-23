resource "aws_instance" "db_bastion" {
  ami                         = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type               = "t3.micro"
  key_name                    = var.ec2_key_pair_name
  vpc_security_group_ids      = [aws_security_group.db_bastion.id]
  subnet_id                   = aws_subnet.db_public[0].id
  associate_public_ip_address = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-db-bastion" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_instance" "database" {
  ami                         = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.database.id]
  subnet_id                   = aws_subnet.db_private[0].id
  key_name                    = var.ec2_key_pair_name

  user_data = base64encode(templatefile("${path.module}/scripts/database.sh", {
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
  }))

  tags = merge(
    { "Name" = "${var.main_project_tag}-database" },
    { "Project" = var.main_project_tag }
  )

  depends_on = [aws_nat_gateway.db_nat]
}