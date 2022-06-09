## General Instance Trust Policy
data "aws_iam_policy_document" "instance_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

# Consul Instance IAM Role, Policy, and Profile
resource "aws_iam_role" "consul_instance" {
  name_prefix        = "${var.main_project_tag}-role-"
  assume_role_policy = data.aws_iam_policy_document.instance_trust_policy.json
}

# Consul Instance Permissions Policy
data "aws_iam_policy_document" "instance_permissions_policy" {
  statement {
    sid    = "DescribeInstances" # change this to describe instances...
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "consul_instance_policy" {
  name_prefix = "${var.main_project_tag}-instance-policy-"
  role        = aws_iam_role.consul_instance.id
  policy      = data.aws_iam_policy_document.instance_permissions_policy.json
}

resource "aws_iam_instance_profile" "consul_instance_profile" {
  name_prefix = "${var.main_project_tag}-instance-profile-"
  role        = aws_iam_role.consul_instance.name
}

# Consul CTS IAM Role, Policy, and Profile

resource "aws_iam_role" "consul_cts_instance" {
  name_prefix        = "${var.main_project_tag}-cts-role-"
  assume_role_policy = data.aws_iam_policy_document.instance_trust_policy.json
  # TODO: limit permissions to just what's needed for CTS
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  ]
}

resource "aws_iam_instance_profile" "consul_cts_instance_profile" {
  name_prefix = "${var.main_project_tag}-cts-instance-profile-"
  role        = aws_iam_role.consul_cts_instance.name
}