mkdir -p tokens

export CONSUL_HTTP_ADDR=http://$(terraform output -raw consul_server)
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_token)

echo "client_api_service_token = \"$(consul acl token create -service-identity="api:dc1" -format=json | jq -r .SecretID)\"" > tokens.auto.tfvars
echo "client_web_service_token = \"$(consul acl token create -service-identity="web:dc1" -format=json | jq -r .SecretID)\"" >> tokens.auto.tfvars