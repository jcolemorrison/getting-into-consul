# This requires the following to be installed:
# 1. Terraform
# 2. Consul
# 3. jq
# 4. AWS CLI with credentials set up

export CONSUL_HTTP_ADDR=http://$(terraform output -raw consul_server)
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_token)
export API_ASG_NAME=$(terraform output -raw asg_api_name)
export API_V2_ASG_NAME=$(terraform output -raw asg_api_v2_name)
export WEB_ASG_NAME=$(terraform output -raw asg_web_name)
export AWS_REGION=$(terraform output -raw aws_region)

echo "Creating tokens..."

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
	echo "client_api_node_id_token_$API_NODE = \"$(consul acl token create -service-identity="$hostname:dc1" -format=json | jq -r .SecretID)\"" > tokens.txt
	API_NODE=$((API_NODE++))
done

# Node Identity Tokens - API v2
API_V2_INSTANCES=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids \
	$(aws autoscaling describe-auto-scaling-instances --region us-east-1 --output text \
			--query "AutoScalingInstances[?AutoScalingGroupName=='$API_V2_ASG_NAME'].InstanceId") \
--query "Reservations[].Instances[].PrivateIpAddress" | jq -r '.[]')

API_V2_NODE=0
for node in $API_V2_INSTANCES
do
	# Assumes hostnames on AWS EC2 take the form of ip-*-*-*-*
	hostname="ip-${node//./-}"
	echo "client_api_v2_node_id_token_$API_V2_NODE = \"$(consul acl token create -service-identity="$hostname:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
	API_V2_NODE=$((API_V2_NODE++))
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
	echo "client_web_node_id_token_$WEB_NODE = \"$(consul acl token create -service-identity="$hostname:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
	WEB_NODE=$((WEB_NODE++))
done

# Service Tokens
echo "client_api_service_token = \"$(consul acl token create -service-identity="api:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt
echo "client_web_service_token = \"$(consul acl token create -service-identity="web:dc1" -format=json | jq -r .SecretID)\"" >> tokens.txt

echo "Created!  To complete setup reference the tokens in tokens.txt..."
echo "1. Add the 'consul_api_node_id_token' to the consul.hcl file on your Consul Client API nodes under the acl.tokens block."
echo "2. Add the 'consul_api_service_token' to the api.hcl file on your Consul Client API nodes under the service.token block."
echo "3. Restart consul and the api service on the Consul Client API nodes."
echo "4. Add the 'consul_web_node_id_token' to the consul.hcl file on your Consul Client WEB nodes under the acl.tokens block."
echo "5. Add the 'consul_web_service_token' to the web.hcl file on your Consul Client WEB nodes under the service.token block."
echo "6. Restart consul and the web service on the Consul Client WEB nodes."
echo "7. For both global node-identity tokens, create and attach the policy shown in policies/allow-dns.hcl."
echo "For more details, checkout the README.md"

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