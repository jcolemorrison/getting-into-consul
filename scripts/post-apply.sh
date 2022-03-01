# This requires the following to be installed:
# 1. Terraform
# 2. Consul
# 3. jq
# 4. AWS CLI with credentials set up

export CONSUL_HTTP_ADDR=http://$(terraform output -raw consul_server)
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_token)
export API_ASG_NAME=$(terraform output -raw asg_api_name)
# export API_V2_ASG_NAME=$(terraform output -raw asg_api_v2_name)
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

# Node Identity Tokens - API v2
# API_V2_INSTANCES=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids \
# 	$(aws autoscaling describe-auto-scaling-instances --region us-east-1 --output text \
# 			--query "AutoScalingInstances[?AutoScalingGroupName=='$API_V2_ASG_NAME'].InstanceId") \
# --query "Reservations[].Instances[].PrivateIpAddress" | jq -r '.[]')

# API_V2_NODE=0
# for node in $API_V2_INSTANCES
# do
# 	# Assumes hostnames on AWS EC2 take the form of ip-*-*-*-*
# 	hostname="ip-${node//./-}"
# 	echo "client_api_v2_node_id_token_$API_V2_NODE = \"$(consul acl token create -node-identity="$hostname:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
# 	API_V2_NODE=$((API_V2_NODE++))
# done

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

# Service Tokens
echo "client_api_service_token = \"$(consul acl token create -service-identity="api:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "client_web_service_token = \"$(consul acl token create -service-identity="web:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "client_ig_service_token = \"$(consul acl token create -service-identity="ig:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "client_tm_service_token = \"$(consul acl token create -service-identity="tm:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt

# Values for the Metrics Module - yes, this is a lot.  Done, because we can't grab the necesseary IPs
# of consul servers until the root module is completely deployed.
export MAIN_TAG=$(terraform output -raw main_project_tag)
export VPC_ID=$(terraform output -raw vpc_id)
export VPC_PRIVATE_SUBNET_IDS=$(terraform output -json vpc_private_subnet_ids)
export VPC_PUBLIC_SUBNET_IDS=$(terraform output -json vpc_public_subnet_ids)
export EC2_KEY_PAIR_NAME=$(terraform output -raw ec2_key_pair_name)
export BASTION_SECURITY_GROUP_ID=$(terraform output -raw bastion_security_group_id)
export CONSUL_SERVER_SECURITY_GROUP_ID=$(terraform output -raw consul_server_security_group_id)
export CONSUL_CLIENT_SECURITY_GROUP_ID=$(terraform output -raw consul_client_security_group_id)
export CONSUL_TOKEN=$(terraform output -raw consul_token)

# Retrieve Consul Server Private IP
export CONSUL_SERVER_ASG_NAME=$(terraform output -raw asg_consul_server_name)
# TODO - account for multiple server IPs
SERVER_INSTANCE_IP=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids \
	$(aws autoscaling describe-auto-scaling-instances --region us-east-1 --output text \
			--query "AutoScalingInstances[?AutoScalingGroupName=='$CONSUL_SERVER_ASG_NAME'].InstanceId") \
--query "Reservations[].Instances[].PrivateIpAddress" | jq -r '.[]')

# Append Terraform Variables for the Metrics Module
cat > `pwd -P`/metrics_module/terraform.tfvars <<- EOF
main_project_tag = "${MAIN_TAG}"
vpc_id = "${VPC_ID}"
vpc_private_subnet_ids = ${VPC_PRIVATE_SUBNET_IDS}
vpc_public_subnet_ids = ${VPC_PUBLIC_SUBNET_IDS}
ec2_key_pair_name = "${EC2_KEY_PAIR_NAME}"
bastion_security_group_id = "${BASTION_SECURITY_GROUP_ID}"
consul_server_security_group_id = "${CONSUL_SERVER_SECURITY_GROUP_ID}"
consul_client_security_group_id = "${CONSUL_CLIENT_SECURITY_GROUP_ID}"
consul_server_ip = "${SERVER_INSTANCE_IP}"
consul_token = "${CONSUL_TOKEN}"
EOF

# Set up for the Database
export DB_PRIVATE_IP=$(terraform output -raw database_private_ip)
export DB_BASTION_IP=$(terraform output -raw db_bastion_ip)

db_hostname="ip-${DB_PRIVATE_IP//./-}"

echo "client_db_node_id_token = \"$(consul acl token create -node-identity="$db_hostname:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "client_db_service_token = \"$(consul acl token create -service-identity="db:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt

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

# echo ""
# echo "Part 2 - API v2 Instances..."
# echo "1. SSH into your Bastion at ${BASTION_IP}.  From there SSH into your getting-into-consul-api-v2 server at ${API_V2_INSTANCES}."
# echo "2. Add the 'client_api_v2_node_id_token_0' to the '/etc/consul.d/consul.hcl' file under the acl.tokens block."
# echo "3. Add the 'consul_api_service_token' to the '/etc/consul.d/api.hcl' file under the service.token block."
# echo "4. Add the 'consul_api_service_token' to the '/etc/systemd/system/consul-envoy.service' file for the '-token=' flag."
# echo "5. Run 'systemctl daemon-reload' and then 'systemctl restart consul';  'systemctl restart api'; 'systemctl restart consul-envoy';"

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
echo "1. 'cd' into the nested 'metrics_module' directory."
echo "2. Run 'terraform init'."
echo "3. Run 'terraform apply'."

echo ""
echo "Visit your Consul Server at ${CONSUL_HTTP_ADDR}."
echo "Visit your Web Server at ${WEB_HTTP_ADDR}."
echo "For the Metrics Server, after running 'terraform apply' in the 'metrics_module' visit the 'metrics_endpoint'."

echo ""
echo "For more details, checkout the README.md"
echo ""