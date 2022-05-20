# This requires the following to be installed:
# 1. Terraform
# 2. Consul
# 3. jq
# 4. AWS CLI with credentials set up

export CONSUL_HTTP_ADDR=http://$(terraform output -raw consul_server)
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_token)
export API_ASG_NAME=$(terraform output -raw asg_api_name)
export WEB_ASG_NAME=$(terraform output -raw asg_web_name)
export AWS_REGION=$(terraform output -raw aws_region)
export BASTION_IP=$(terraform output -raw bastion_ip)
export WEB_HTTP_ADDR=http://$(terraform output -raw web_server)

echo ""
echo "Creating ACL tokens and setting up values for the optional Metrics deployment..."

# Node Identity Tokens - API
API_INSTANCES=$(aws ec2 describe-instances --region $AWS_REGION \
	--filters Name=tag:Name,Values=getting-into-consul-api \
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
WEB_INSTANCES=$(aws ec2 describe-instances --region $AWS_REGION \
	--filters Name=tag:Name,Values=getting-into-consul-web \
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
echo "client_web_service_token = \"$(consul acl token create -service-identity="web" -format=json | jq -r .SecretID)\"" >> tokens.txt

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
echo "(Optional) Part 3 - Deploying the Prometheus Metrics Server..."
echo "1. Run the post-apply-metrics.sh script."
echo "2. Follow instructions from aforementioned script."

echo ""
echo "Visit your Consul Server at ${CONSUL_HTTP_ADDR}."
echo "Visit your Web Server at ${WEB_HTTP_ADDR}."

echo ""
echo "For more details, checkout the README.md"
echo ""