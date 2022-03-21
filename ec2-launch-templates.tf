# Generate Consul gossip encryption key
resource "random_id" "gossip_key" {
  byte_length = 32
}

## Set bootstrap ACL token
resource "random_uuid" "consul_bootstrap_token" {}

# Consul Server Launch Template
resource "aws_launch_template" "consul_server" {
  name_prefix            = "${var.main_project_tag}-server-lt-"
  image_id               = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
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
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
    BOOTSTRAP_NUMBER = var.server_min_count
    GOSSIP_KEY = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY = tls_self_signed_cert.ca_cert.cert_pem
    SERVER_PUBLIC_KEY = tls_locally_signed_cert.server_signed_cert.cert_pem
    SERVER_PRIVATE_KEY = tls_private_key.server_key.private_key_pem
    BOOTSTRAP_TOKEN    = random_uuid.consul_bootstrap_token.result
  }))
}

# Consul Client Web Launch Template
resource "aws_launch_template" "consul_client_web" {
  name_prefix            = "${var.main_project_tag}-web-lt-"
  image_id               = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
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
    GOSSIP_KEY = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY = tls_self_signed_cert.ca_cert.cert_pem
    CLIENT_PUBLIC_KEY = tls_locally_signed_cert.client_web_signed_cert.cert_pem
    CLIENT_PRIVATE_KEY = tls_private_key.client_web_key.private_key_pem
  }))
}

# Consul Client API Launch Template
resource "aws_launch_template" "consul_client_api" {
  name_prefix            = "${var.main_project_tag}-api-lt-"
  image_id               = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
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
    GOSSIP_KEY = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY = tls_self_signed_cert.ca_cert.cert_pem
    CLIENT_PUBLIC_KEY = tls_locally_signed_cert.client_api_signed_cert.cert_pem
    CLIENT_PRIVATE_KEY = tls_private_key.client_api_key.private_key_pem
  }))
}

# Ingress Gateway Launch Template
resource "aws_launch_template" "ingress_gateway" {
  name_prefix            = "${var.main_project_tag}-ingress-lt-"
  image_id               = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.ingress_gateway.id]

  # add IAM role for auto discover
  iam_instance_profile {
    name = aws_iam_instance_profile.consul_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "${var.main_project_tag}-ingress-gateway" },
      { "Project" = var.main_project_tag }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      { "Name" = "${var.main_project_tag}-ingress-gateway-volume" },
      { "Project" = var.main_project_tag }
    )
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-ingress-gateway-lt" },
    { "Project" = var.main_project_tag }
  )

  user_data = base64encode(templatefile("${path.module}/scripts/ingress-gateway.sh", {
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
    GOSSIP_KEY = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY = tls_self_signed_cert.ca_cert.cert_pem
    CLIENT_PUBLIC_KEY = tls_locally_signed_cert.ingress_gateway_signed_cert.cert_pem
    CLIENT_PRIVATE_KEY = tls_private_key.ingress_gateway_key.private_key_pem
  }))
}

# Terminating Gateway Launch Template
resource "aws_launch_template" "terminating_gateway" {
  name_prefix            = "${var.main_project_tag}-terminating-lt-"
  image_id               = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.terminating_gateway.id]

  # add IAM role for auto discover
  iam_instance_profile {
    name = aws_iam_instance_profile.consul_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "${var.main_project_tag}-terminating-gateway" },
      { "Project" = var.main_project_tag }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      { "Name" = "${var.main_project_tag}-terminating-gateway-volume" },
      { "Project" = var.main_project_tag }
    )
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-terminating-gateway-lt" },
    { "Project" = var.main_project_tag }
  )

  user_data = base64encode(templatefile("${path.module}/scripts/terminating-gateway.sh", {
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
    GOSSIP_KEY = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY = tls_self_signed_cert.ca_cert.cert_pem
    CLIENT_PUBLIC_KEY = tls_locally_signed_cert.terminating_gateway_signed_cert.cert_pem
    CLIENT_PRIVATE_KEY = tls_private_key.terminating_gateway_key.private_key_pem
  }))
}
