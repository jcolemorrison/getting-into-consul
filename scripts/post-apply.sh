# This requires the following to be installed:
# 1. Terraform
# 2. Consul
# 3. jq
# 4. AWS CLI with credentials set up

export CONSUL_HTTP_ADDR=http://$(terraform output -raw consul_server)
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_token)
export API_ASG_NAME=$(terraform output -raw asg_api_name)
export WEB_ASG_NAME=$(terraform output -raw asg_web_name)
export IG_ASG_NAME=$(terraform output -raw asg_ig_name)
export TM_ASG_NAME=$(terraform output -raw asg_tm_name)
export AWS_REGION=$(terraform output -raw aws_region)
export BASTION_IP=$(terraform output -raw bastion_ip)
export WEB_HTTP_ADDR=http://$(terraform output -raw web_server)

echo ""
echo "Creating ACL tokens and setting up values for the optional Metrics deployment..."

# Node Identity Tokens - API
API_INSTANCES=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids \
	$(aws autoscaling describe-auto-scaling-instances --region us-east-1 --output text \
			--query "AutoScalingInstances[?AutoScalingGroupName=='$API_ASG_NAME'].InstanceId") \
--query "Reservations[].Instances[].PrivateIpAddress" | jq -r '.[]')

API_NODE=0
for node in $API_INSTANCES
do
	# Assumes hostnames on AWS EC2 take the form of ip-*-*-*-*
	hostname="ip-${node//./-}"
	# CHANGE TO -node-identity
	echo "client_api_node_id_token_$API_NODE = \"$(consul acl token create -node-identity="$hostname:dc1" -format=json | jq -r .SecretID)\"" > tokens.txt
	API_NODE=$((API_NODE++))
done

# Node Identity Tokens - WEB
WEB_INSTANCES=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids \
	$(aws autoscaling describe-auto-scaling-instances --region us-east-1 --output text \
			--query "AutoScalingInstances[?AutoScalingGroupName=='$WEB_ASG_NAME'].InstanceId") \
--query "Reservations[].Instances[].PrivateIpAddress" | jq -r '.[]')

WEB_NODE=0
for node in $WEB_INSTANCES
do
	# Assumes hostnames on AWS EC2 take the form of ip-*-*-*-*
	hostname="ip-${node//./-}"
	echo "client_web_node_id_token_$WEB_NODE = \"$(consul acl token create -node-identity="$hostname:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
	WEB_NODE=$((WEB_NODE++))
done

# Node Identity Tokens - Terminating Gateways
TM_INSTANCES=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids \
	$(aws autoscaling describe-auto-scaling-instances --region us-east-1 --output text \
			--query "AutoScalingInstances[?AutoScalingGroupName=='$TM_ASG_NAME'].InstanceId") \
--query "Reservations[].Instances[].PrivateIpAddress" | jq -r '.[]')

TM_NODE=0
for node in $TM_INSTANCES
do
	# Assumes hostnames on AWS EC2 take the form of ip-*-*-*-*
	hostname="ip-${node//./-}"
	echo "client_tm_node_id_token_$TM_NODE = \"$(consul acl token create -node-identity="$hostname:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
	TM_NODE=$((TM_NODE++))
done

# Node Identity Tokens - Ingress Gateways
IG_INSTANCES=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids \
	$(aws autoscaling describe-auto-scaling-instances --region us-east-1 --output text \
			--query "AutoScalingInstances[?AutoScalingGroupName=='$IG_ASG_NAME'].InstanceId") \
--query "Reservations[].Instances[].PrivateIpAddress" | jq -r '.[]')

IG_NODE=0
for node in $IG_INSTANCES
do
	# Assumes hostnames on AWS EC2 take the form of ip-*-*-*-*
	hostname="ip-${node//./-}"
	echo "client_ig_node_id_token_$IG_NODE = \"$(consul acl token create -node-identity="$hostname:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
	IG_NODE=$((IG_NODE++))
done

# Service Tokens
echo "client_api_service_token = \"$(consul acl token create -service-identity="api:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "client_web_service_token = \"$(consul acl token create -service-identity="web:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt

# Create the ACL for Terminating Gateway
cat > `pwd -P`/files/terminating-gateway-acl.hcl <<- EOF
service "database" {
	policy = "write"
}
service "tm" {
	policy = "write"
}
service "tm-sidecar-proxy" {
	policy = "write"
}
service_prefix "" {
	policy = "read"
}
node_prefix "" {
	policy = "read"
}
EOF

TM_POLICY_ID=$(consul acl policy create -name "terminating-gateway-db" -description "defaults and allow database service write access" -rules @`pwd -P`/files/terminating-gateway-acl.hcl -valid-datacenter dc1 -format json | jq -r .ID)

# Terminating Gateway Service Token
echo "client_tm_service_token = \"$(consul acl token create -service-identity="tm:dc1" -policy-id="$TM_POLICY_ID" -format=json | jq -r .SecretID)\"" >> tokens.txt

# Ingress Gateway Service Token
echo "client_ig_service_token = \"$(consul acl token create -service-identity="ig:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt

# Set up for the Database
export DB_PRIVATE_IP=$(terraform output -raw database_private_ip)
export DB_BASTION_IP=$(terraform output -raw db_bastion_ip)

DB_HOSTNAME="ip-${DB_PRIVATE_IP//./-}"

echo "client_db_node_id_token = \"$(consul acl token create -node-identity="$DB_HOSTNAME:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "client_db_service_token = \"$(consul acl token create -service-identity="db:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt

# Set up the Database for Terminating Gateway
cat > `pwd -P`/files/database.json <<- EOF
{
  "Node": "${DB_HOSTNAME}",
  "Address": "${DB_PRIVATE_IP}",
  "NodeMeta": {
    "external-node": "true",
    "external-probe": "true"
  },
  "Service": {
    "ID": "database",
    "Service": "database",
    "Port": 5432
  }
}
EOF

# Register the database service
curl --request PUT -H "X-Consul-Token:$CONSUL_HTTP_TOKEN" --data @`pwd -P`/files/database.json "$CONSUL_HTTP_ADDR/v1/catalog/register"

# User Setup Messages
echo ""
echo "To complete setup reference the tokens in tokens.txt.  The tokens are the ACLs that will be used to set up the various Consul Clients."

echo ""
echo "Part 1 - API Instances..."
echo "1. SSH into your Bastion at ${BASTION_IP}.  From there SSH into your getting-into-consul-api server at ${API_INSTANCES}."
echo "2. Add the 'consul_api_node_id_token_0' to the '/etc/consul.d/consul.hcl' file under the acl.tokens block."
echo "3. Add the 'consul_api_service_token' to the '/etc/consul.d/api.hcl' file under the service.token block."
echo "4. Add the 'consul_api_service_token' to the '/etc/systemd/system/consul-envoy.service' file for the '-token=' flag."
echo "5. Run 'systemctl daemon-reload' and then 'systemctl restart consul';  'systemctl restart api'; 'systemctl restart consul-envoy';"

echo ""
echo "Part 2 - Web Instances..."
echo "1. SSH into your Bastion at ${BASTION_IP}.  From there SSH into your getting-into-consul-web server at ${WEB_INSTANCES}."
echo "2. Add the 'client_web_node_id_token_0' to the '/etc/consul.d/consul.hcl' file under the acl.tokens block."
echo "3. Add the 'consul_web_service_token' to the '/etc/consul.d/web.hcl' file under the service.token block."
echo "4. Add the 'consul_web_service_token' to the '/etc/systemd/system/consul-envoy.service' file for the '-token=' flag."
echo "5. Run 'systemctl daemon-reload' and then 'systemctl restart consul';  'systemctl restart web'; 'systemctl restart consul-envoy';"

echo ""
echo "Part 3 - Terminating Gateway Instances..."
echo "1. SSH into your Bastion at ${BASTION_IP}.  From there SSH into your getting-into-consul-tm server at ${TM_INSTANCES}."
echo "2. Add the 'client_tm_node_id_token_0' to the '/etc/consul.d/consul.hcl' file under the acl.tokens block."
echo "3. Add the 'consul_tm_service_token' to the '/etc/consul.d/tm.hcl' file under the service.token block."
echo "4. Add the 'consul_tm_service_token' to the '/etc/systemd/system/consul-envoy.service' file for the '-token=' flag."
echo "5. Run 'systemctl daemon-reload' and then 'systemctl restart consul';  'systemctl restart tm'; 'systemctl restart consul-envoy';"

echo ""
echo "Part 4 - Ingress Gateway Instances..."
echo "1. SSH into your Bastion at ${BASTION_IP}.  From there SSH into your getting-into-consul-ig server at ${IG_INSTANCES}."
echo "2. Add the 'client_ig_node_id_token_0' to the '/etc/consul.d/consul.hcl' file under the acl.tokens block."
echo "3. Add the 'consul_ig_service_token' to the '/etc/consul.d/ig.hcl' file under the service.token block."
echo "4. Add the 'consul_ig_service_token' to the '/etc/systemd/system/consul-envoy.service' file for the '-token=' flag."
echo "5. Run 'systemctl daemon-reload' and then 'systemctl restart consul';  'systemctl restart ig'; 'systemctl restart consul-envoy';"

echo ""
echo "Part 5 - Database Instances..."
echo "1. SSH into your DATABASE Bastion at ${DB_BASTION_IP}.  From there SSH into your getting-into-consul-database server at ${DB_PRIVATE_IP}."
echo "2. Add the 'client_db_node_id_token_0' to the '/etc/consul.d/consul.hcl' file under the acl.tokens block."
echo "3. Add the 'consul_db_service_token' to the '/etc/consul.d/database.hcl' file under the service.token block."
echo "4. Add the 'consul_db_service_token' to the '/etc/systemd/system/consul-envoy.service' file for the '-token=' flag."
echo "5. Run 'systemctl daemon-reload' and then 'systemctl restart consul';  'systemctl restart database'; 'systemctl restart consul-envoy';"

echo ""
echo "(Optional) Part 6 - Deploying the Prometheus Metrics Server..."
echo "1. Run the post-apply.sh script."
echo "2. Follow instructions from aforementioned script."

echo ""
echo "Visit your Consul Server at ${CONSUL_HTTP_ADDR}."
echo "Visit your Web Server at ${WEB_HTTP_ADDR}."

echo ""
echo "For more details, checkout the README.md"
echo ""