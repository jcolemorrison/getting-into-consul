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
  address = "localhost:8500"

  service_registration {
    enabled      = true
    service_name = "cts"
    # address = "10.255.2.221"

    # default_check {
    #   enabled = true
    #   address = "http://10.255.2.221:8558"
    # }
  }
}

driver "terraform" {
  log         = true
  persist_log = false
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
