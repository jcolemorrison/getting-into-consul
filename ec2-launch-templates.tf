# Consul Client Web Launch Template
resource "aws_launch_template" "consul_client_web" {
  name_prefix            = "${var.main_project_tag}-web-lt-"
  image_id               = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.consul_client.id, aws_security_group.hcp_consul_client.id]

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
    CONSUL_ROOT_TOKEN  = hcp_consul_cluster.consul.consul_root_token_secret_id
    CA_PUBLIC_KEY      = base64decode(hcp_consul_cluster.consul.consul_ca_file)
    HCP_CONFIG_FILE    = base64decode(hcp_consul_cluster.consul.consul_config_file)
  }))
}

# Consul Client API Launch Template
resource "aws_launch_template" "consul_client_api" {
  name_prefix            = "${var.main_project_tag}-api-lt-"
  image_id               = var.use_latest_ami ? data.aws_ssm_parameter.ubuntu_1804_ami_id.value : var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.consul_client.id, aws_security_group.hcp_consul_client.id]

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
    CONSUL_ROOT_TOKEN  = hcp_consul_cluster.consul.consul_root_token_secret_id
    CA_PUBLIC_KEY      = base64decode(hcp_consul_cluster.consul.consul_ca_file)
    HCP_CONFIG_FILE    = base64decode(hcp_consul_cluster.consul.consul_config_file)
  }))
}
