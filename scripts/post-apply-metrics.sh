# This requires the following to be installed:
# 1. Terraform
# 2. Consul
# 3. jq
# 4. AWS CLI with credentials set up
# 5. The ./post-apply.sh script to have been run!

export AWS_REGION=$(terraform output -raw aws_region)
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

echo ""
echo "To Deploy the Prometheus Metrics Server..."
echo "1. 'cd' into the nested 'metrics_module' directory."
echo "2. Run 'terraform init'."
echo "3. Run 'terraform apply'."
echo ""

echo "For the Metrics Server, after running 'terraform apply' in the 'metrics_module' visit the 'metrics_endpoint'."