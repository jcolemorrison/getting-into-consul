mkdir -p tokens
export CONSUL_HTTP_ADDR=http://$(terraform output -raw consul_server)
consul acl bootstrap -format=json >> tokens/bootstrap.json
export CONSUL_HTTP_TOKEN=$(cat tokens/bootstrap.json | jq -r .SecretID)
consul acl token create -service-identity="api:dc1" -format=json >> tokens/api.json
consul acl token create -service-identity="web:dc1" -format=json >> tokens/web.json
consul acl policy create -name "dns-requests" \
                         -description "Allow requests to resolve DNS" \
                         -datacenter "dc1" \
                         -rules @policies/allow-dns.hcl