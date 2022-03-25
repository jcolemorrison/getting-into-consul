# This requires the following to be installed:
# 1. Terraform
# 2. Consul
# 3. jq
# 4. AWS CLI with credentials set up

export CONSUL_HTTP_ADDR=http://$(terraform output -raw consul_server)
export CONSUL_HTTP_ADDR_DC2=http://$(terraform output -raw consul_server_dc2)
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_token)
export API_ASG_NAME=$(terraform output -raw asg_api_name)
export API_ASG_DC2_NAME=$(terraform output -raw asg_api_dc2_name)
export WEB_ASG_NAME=$(terraform output -raw asg_web_name)
export AWS_REGION=$(terraform output -raw aws_region)
export BASTION_IP=$(terraform output -raw bastion_ip)
export BASTION_IP_DC2=$(terraform output -raw bastion_ip_dc2)
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

# Node Identity Tokens - API dc2
API_DC2_INSTANCES=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids \
	$(aws autoscaling describe-auto-scaling-instances --region us-east-1 --output text \
			--query "AutoScalingInstances[?AutoScalingGroupName=='$API_ASG_DC2_NAME'].InstanceId") \
--query "Reservations[].Instances[].PrivateIpAddress" | jq -r '.[]')

API_DC2_NODE=0
for node in $API_DC2_INSTANCES
do
	# Assumes hostnames on AWS EC2 take the form of ip-*-*-*-*
	hostname="ip-${node//./-}"
	# CHANGE TO -node-identity
	echo "client_api_dc2_node_id_token_$API_DC2_NODE = \"$(consul acl token create -http-addr="$CONSUL_HTTP_ADDR_DC2" -node-identity="$hostname:dc2" -format=json | jq -r .SecretID)\"" >> tokens.txt
	API_DC2_NODE=$((API_DC2_NODE++))
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

# Service Tokens
echo "client_api_service_token = \"$(consul acl token create -service-identity="api:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "client_api_dc2_service_token = \"$(consul acl token create -http-addr="$CONSUL_HTTP_ADDR_DC2" -service-identity="api:dc2" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "client_web_service_token = \"$(consul acl token create -service-identity="web:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt

# Set up for the Mesh Gateway DC1
export MESH_GATEWAY_PRIVATE_IP=$(terraform output -raw mesh_gateway_private_ip)

MESH_GATEWAY_HOSTNAME="ip-${MESH_GATEWAY_PRIVATE_IP//./-}"

echo "mesh_gateway_node_id_token = \"$(consul acl token create -node-identity="$MESH_GATEWAY_HOSTNAME:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "mesh_gateway_service_token = \"$(consul acl token create -service-identity="meshgateway:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt

# Set up for the Mesh Gateway DC2
export MESH_GATEWAY_PRIVATE_IP_DC2=$(terraform output -raw mesh_gateway_private_ip_dc2)

MESH_GATEWAY_HOSTNAME_DC2="ip-${MESH_GATEWAY_PRIVATE_IP_DC2//./-}"

echo "mesh_gateway_dc2_node_id_token = \"$(consul acl token create -http-addr="$CONSUL_HTTP_ADDR_DC2" -node-identity="$MESH_GATEWAY_HOSTNAME_DC2:dc2" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "mesh_gateway_dc2_service_token = \"$(consul acl token create -http-addr="$CONSUL_HTTP_ADDR_DC2" -service-identity="meshgateway:dc2" -format=json | jq -r .SecretID)\"" >> tokens.txt

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
echo "Part 3 - Mesh Gateway Dc1 Instance..."
echo "1. SSH into your Bastion at ${BASTION_IP}.  From there SSH into your getting-into-consul-mesh-gateway server at ${MESH_GATEWAY_PRIVATE_IP}."
echo "2. Add the 'mesh_gateway_node_id_token' to the '/etc/consul.d/consul.hcl' file under the acl.tokens block."
echo "3. Add the 'mesh_gateway_service_token' to the '/etc/systemd/system/consul-envoy.service' file for the '-token=' flag."
echo "5. Run 'systemctl daemon-reload' and then 'systemctl restart consul'; 'systemctl restart consul-envoy';"

echo ""
echo "Part 4 - Mesh Gateway Dc2 Instance..."
echo "1. SSH into your Bastion in DC2 at ${BASTION_IP_DC2}.  From there SSH into your getting-into-consul-mesh-gateway-dc2 server at ${MESH_GATEWAY_PRIVATE_IP_DC2}."
echo "2. Add the 'mesh_gateway_dc2_node_id_token' to the '/etc/consul.d/consul.hcl' file under the acl.tokens block."
echo "3. Add the 'mesh_gateway_dc2_service_token' to the '/etc/systemd/system/consul-envoy.service' file for the '-token=' flag."
echo "5. Run 'systemctl daemon-reload' and then 'systemctl restart consul'; 'systemctl restart consul-envoy';"

echo ""
echo "Part 5 - API Dc2 Instances..."
echo "1. SSH into your Bastion in DC2 at ${BASTION_IP_DC2}.  From there SSH into your getting-into-consul-api-dc2 server at ${API_DC2_INSTANCES}."
echo "2. Add the 'consul_api_dc2_node_id_token_0' to the '/etc/consul.d/consul.hcl' file under the acl.tokens block."
echo "3. Add the 'consul_api_dc2_service_token' to the '/etc/consul.d/api.hcl' file under the service.token block."
echo "4. Add the 'consul_api_dc2_service_token' to the '/etc/systemd/system/consul-envoy.service' file for the '-token=' flag."
echo "5. Run 'systemctl daemon-reload' and then 'systemctl restart consul';  'systemctl restart api'; 'systemctl restart consul-envoy';"

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