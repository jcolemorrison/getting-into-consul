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
    PROJECT_TAG        = "Project"
    PROJECT_VALUE      = var.main_project_tag
    GOSSIP_KEY         = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY      = tls_self_signed_cert.ca_cert.cert_pem
    CLIENT_PUBLIC_KEY  = tls_locally_signed_cert.client_web_signed_cert.cert_pem
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
    PROJECT_TAG        = "Project"
    PROJECT_VALUE      = var.main_project_tag
    GOSSIP_KEY         = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY      = tls_self_signed_cert.ca_cert.cert_pem
    CLIENT_PUBLIC_KEY  = tls_locally_signed_cert.client_api_signed_cert.cert_pem
    CLIENT_PRIVATE_KEY = tls_private_key.client_api_key.private_key_pem
  }))
}

# Consul Client API v2 Launch Template
resource "aws_launch_template" "consul_client_api_v2" {
  name_prefix            = "${var.main_project_tag}-api-v2-lt-"
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
      { "Name" = "${var.main_project_tag}-api-v2" },
      { "Project" = var.main_project_tag }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      { "Name" = "${var.main_project_tag}-api-v2-volume" },
      { "Project" = var.main_project_tag }
    )
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-api-v2-lt" },
    { "Project" = var.main_project_tag }
  )

  user_data = base64encode(templatefile("${path.module}/scripts/client-api-v2.sh", {
    PROJECT_TAG   = "Project"
    PROJECT_VALUE = var.main_project_tag
    GOSSIP_KEY = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY = tls_self_signed_cert.ca_cert.cert_pem
    CLIENT_PUBLIC_KEY = tls_locally_signed_cert.client_api_v2_signed_cert.cert_pem
    CLIENT_PRIVATE_KEY = tls_private_key.client_api_v2_key.private_key_pem
  }))
}