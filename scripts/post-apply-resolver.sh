#!/bin/bash

export CONSUL_HTTP_ADDR=http://$(terraform output -raw consul_server)
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_token)

echo 'Kind = "service-resolver"
Name = "api"
Redirect {
  Datacenter = "dc2"
}' | consul config write -

