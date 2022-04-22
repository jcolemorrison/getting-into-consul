data "aws_ssm_parameter" "ubuntu_1804_ami_id" {
  name = "/aws/service/canonical/ubuntu/server/18.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

resource "aws_instance" "bastion" {
  ami                         = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
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
  count = var.server_desired_count

  ami                         = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.consul_server.id]
  subnet_id                   = aws_subnet.private[count.index].id
  key_name                    = var.ec2_key_pair_name

  iam_instance_profile = aws_iam_instance_profile.consul_instance_profile.name

  private_ip = local.server_private_ips[count.index]

  user_data = base64encode(templatefile("${path.module}/scripts/server.sh", {
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
    BOOTSTRAP_NUMBER = var.server_desired_count
    GOSSIP_KEY = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY = tls_self_signed_cert.ca_cert.cert_pem
    SERVER_PUBLIC_KEY = tls_locally_signed_cert.server_signed_cert[count.index].cert_pem
    SERVER_PRIVATE_KEY = tls_private_key.server_key[count.index].private_key_pem
    BOOTSTRAP_TOKEN    = random_uuid.consul_bootstrap_token.result
  }))

  tags = merge(
    { "Name" = "${var.main_project_tag}-server" },
    { "Project" = var.main_project_tag }
  )

  depends_on = [aws_nat_gateway.nat]
}

resource "aws_instance" "mesh_gateway" {
  ami                         = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.mesh_gateway.id]
  subnet_id                   = aws_subnet.private[0].id
  key_name                    = var.ec2_key_pair_name

  iam_instance_profile = aws_iam_instance_profile.consul_instance_profile.name

  user_data = base64encode(templatefile("${path.module}/scripts/mesh-gateway.sh", {
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
    GOSSIP_KEY = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY = tls_self_signed_cert.ca_cert.cert_pem
    CLIENT_PUBLIC_KEY = tls_locally_signed_cert.mesh_gateway_signed_cert.cert_pem
    CLIENT_PRIVATE_KEY = tls_private_key.mesh_gateway_key.private_key_pem
  }))

  tags = merge(
    { "Name" = "${var.main_project_tag}-mesh-gateway" },
    { "Project" = var.main_project_tag }
  )

  depends_on = [aws_nat_gateway.nat]
}