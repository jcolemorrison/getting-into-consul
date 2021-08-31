resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  key_name                    = var.ec2_key_pair_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-bastion" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_instance" "consul_server" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.consul_server.id]
  subnet_id              = aws_subnet.private[0].id
  iam_instance_profile   = aws_iam_instance_profile.consul_instance_profile.name

  tags = merge(
    { "Name" = "${var.main_project_tag}-server" },
    { "Project" = var.main_project_tag }
  )

  user_data = base64encode(templatefile("${path.module}/scripts/server.sh", {
    # for injecting variables
  }))
}

resource "aws_instance" "consul_client_web" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.consul_client.id]
  subnet_id              = aws_subnet.private[1].id
  iam_instance_profile   = aws_iam_instance_profile.consul_instance_profile.name

  tags = merge(
    { "Name" = "${var.main_project_tag}-client-web" },
    { "Project" = var.main_project_tag }
  )

  user_data = base64encode(templatefile("${path.module}/scripts/client-web.sh", {
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
  }))
}

resource "aws_instance" "consul_client_api" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.consul_client.id]
  subnet_id              = aws_subnet.private[1].id
  iam_instance_profile   = aws_iam_instance_profile.consul_instance_profile.name

  tags = merge(
    { "Name" = "${var.main_project_tag}-client-api" },
    { "Project" = var.main_project_tag }
  )

  user_data = base64encode(templatefile("${path.module}/scripts/client-api.sh", {
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
  }))
}