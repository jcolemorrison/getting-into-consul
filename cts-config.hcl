log_level   = "INFO"
working_dir = "sync-tasks"
port        = 8558

syslog {}

buffer_period {
  enabled = true
  min     = "5s"
  max     = "20s"
}

consul {
  address = "https://consul-server:8501"
  tls {
    enabled = true
    verify  = false
  }
  service_registration {
    enabled      = true
    service_name = "Consul-Terraform-Sync"
    default_check {
      enabled = true
      address = "http://consul-terraform-sync:8558"
    }
  }
}

driver "terraform" {
  log         = false
  persist_log = true
  backend "local" {}
}

terraform_provider "aws" {
  region = "us-east-1"
}

task {
  name           = "api"
  description    = "Task to configure an AWS ALB for the API service"
  module         = "github.com/jcolemorrison/getting-into-consul//cts_module"
  providers      = ["aws"]
  variable_files = ["terraform.tfvars"]

  condition "services" {
    names      = ["api"]
    datacenter = "dc1"
  }
}
