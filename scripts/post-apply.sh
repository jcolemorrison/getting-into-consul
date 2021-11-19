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
