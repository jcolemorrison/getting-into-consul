export CONSUL_HTTP_ADDR=http://$(terraform output -raw consul_server)
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_token)
export DB_PRIVATE_IP=$(terraform output -raw database_private_ip)

db_hostname="ip-${DB_PRIVATE_IP//./-}"

echo "client_db_node_id_token = \"$(consul acl token create -service-identity="$db_hostname:dc1" -format=json | jq -r .SecretID)\""
echo "client_db_service_token = \"$(consul acl token create -service-identity="db:dc1" -format=json | jq -r .SecretID)\""