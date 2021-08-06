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

  tags = merge(
    { "Name" = "${var.main_project_tag}-server" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_instance" "consul_client" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.consul_client.id]
  subnet_id              = aws_subnet.private[1].id

  tags = merge(
    { "Name" = "${var.main_project_tag}-client" },
    { "Project" = var.main_project_tag }
  )
}