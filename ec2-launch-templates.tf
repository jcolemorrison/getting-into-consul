# Generate Consul gossip encryption key
resource "random_id" "gossip_key" {
  byte_length = 32
}

## Set bootstrap ACL token
resource "random_uuid" "consul_bootstrap_token" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Consul Server Launch Template
resource "aws_launch_template" "consul_server" {
  name_prefix            = "${var.main_project_tag}-server-lt-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.consul_server.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.consul_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "${var.main_project_tag}-server" },
      { "Project" = var.main_project_tag }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      { "Name" = "${var.main_project_tag}-server-volume" },
      { "Project" = var.main_project_tag }
    )
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-server-lt" },
    { "Project" = var.main_project_tag }
  )

  user_data = base64encode(templatefile("${path.module}/scripts/server.sh", {
    PROJECT_TAG        = "Project"
    PROJECT_VALUE      = var.main_project_tag
    BOOTSTRAP_NUMBER   = var.server_min_count
    GOSSIP_KEY         = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY      = tls_self_signed_cert.ca_cert.cert_pem
    SERVER_PUBLIC_KEY  = tls_locally_signed_cert.server_signed_cert.cert_pem
    SERVER_PRIVATE_KEY = tls_private_key.server_key.private_key_pem
    BOOTSTRAP_TOKEN    = random_uuid.consul_bootstrap_token.result
    VAULT_ISSUER_URL   = "${module.hcp.hcp_vault_private_endpoint}/v1/admin/identity/oidc"
  }))
}

# Consul Client Web Launch Template
resource "aws_launch_template" "consul_client_web" {
  name_prefix            = "${var.main_project_tag}-web-lt-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.consul_client.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.consul_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "${var.main_project_tag}-web" },
      { "Project" = var.main_project_tag }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      { "Name" = "${var.main_project_tag}-web-volume" },
      { "Project" = var.main_project_tag }
    )
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-web-lt" },
    { "Project" = var.main_project_tag }
  )

  user_data = base64encode(templatefile("${path.module}/scripts/client-web.sh", {
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
    GOSSIP_KEY    = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY = tls_self_signed_cert.ca_cert.cert_pem
    SERVICE_TOKEN = var.client_web_service_token
  }))
}

# Consul Client API Launch Template
resource "aws_launch_template" "consul_client_api" {
  name_prefix            = "${var.main_project_tag}-api-lt-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.consul_client.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.consul_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "${var.main_project_tag}-api" },
      { "Project" = var.main_project_tag }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      { "Name" = "${var.main_project_tag}-api-volume" },
      { "Project" = var.main_project_tag }
    )
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-api-lt" },
    { "Project" = var.main_project_tag }
  )

  user_data = base64encode(templatefile("${path.module}/scripts/client-api.sh", {
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
    GOSSIP_KEY    = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY = tls_self_signed_cert.ca_cert.cert_pem
    SERVICE_TOKEN = var.client_api_service_token
  }))
}
