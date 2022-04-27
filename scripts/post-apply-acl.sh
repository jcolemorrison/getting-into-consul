#!/bin/bash

export CONSUL_HTTP_ADDR=http://$(terraform output -raw consul_server)
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_token)

consul acl policy create -name replication -rules @policies/replication-policy.hcl
echo "acl_replication_token = \"$(consul acl token create -description "ACL replication token" -policy-name replication -format=json | jq -r .SecretID)\"" > tokens-acl.txt