terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.49.0"
    }
  }
}

provider "aws" {
  region = var.aws_default_region
}

# filter out wavelength zones
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "group-name"
    values = ["us-east-1"]
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}