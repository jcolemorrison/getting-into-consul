resource "aws_instance" "bastion_dc2" {
  ami                         = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type               = "t3.micro"
  key_name                    = var.ec2_key_pair_name
  vpc_security_group_ids      = [aws_security_group.bastion_dc2.id]
  subnet_id                   = aws_subnet.dc2_public[0].id
  associate_public_ip_address = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-bastion-dc2" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_instance" "consul_server_dc2" {
  count = var.server_desired_count_dc2

  ami                    = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.consul_server_dc2.id]
  subnet_id              = aws_subnet.dc2_private[count.index].id
  key_name               = var.ec2_key_pair_name

  iam_instance_profile = aws_iam_instance_profile.consul_instance_profile.name

  private_ip = local.server_private_ips_dc2[count.index]

  user_data = base64encode(templatefile("${path.module}/scripts/server-dc2.sh", {
    PROJECT_TAG                = "Project"
    PROJECT_VALUE              = var.main_project_tag
    BOOTSTRAP_NUMBER           = var.server_desired_count_dc2
    GOSSIP_KEY                 = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY              = tls_self_signed_cert.ca_cert.cert_pem
    SERVER_PUBLIC_KEY          = tls_locally_signed_cert.server_signed_cert_dc2[count.index].cert_pem
    SERVER_PRIVATE_KEY         = tls_private_key.server_key_dc2[count.index].private_key_pem
    BOOTSTRAP_TOKEN            = random_uuid.consul_bootstrap_token.result
    PRIMARY_GATEWAY_IP_ADDRESS = aws_instance.mesh_gateway.private_ip
  }))

  tags = merge(
    { "Name" = "${var.main_project_tag}-server-dc2" },
    { "Project" = var.main_project_tag }
  )

  depends_on = [aws_nat_gateway.dc2_nat]
}

resource "aws_instance" "mesh_gateway_dc2" {
  ami                    = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.mesh_gateway_dc2.id]
  subnet_id              = aws_subnet.dc2_private[0].id
  key_name               = var.ec2_key_pair_name

  iam_instance_profile = aws_iam_instance_profile.consul_instance_profile.name

  user_data = base64encode(templatefile("${path.module}/scripts/mesh-gateway-dc2.sh", {
    PROJECT_TAG        = "Project"
    PROJECT_VALUE      = var.main_project_tag
    GOSSIP_KEY         = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY      = tls_self_signed_cert.ca_cert.cert_pem
    CLIENT_PUBLIC_KEY  = tls_locally_signed_cert.mesh_gateway_dc2_signed_cert.cert_pem
    CLIENT_PRIVATE_KEY = tls_private_key.mesh_gateway_dc2_key.private_key_pem
  }))

  tags = merge(
    { "Name" = "${var.main_project_tag}-mesh-gateway-dc2" },
    { "Project" = var.main_project_tag }
  )

  depends_on = [aws_nat_gateway.dc2_nat]
}