# Getting into Consul

This is the repo used in the [Getting into HashiCorp Consul](https://www.youtube.com/playlist?list=PL81sUbsFNc5b8i2g2sB_tG-PuZxEdlDpK) series where we walk through building out a Consul based architecture and cluster, on AWS, from scratch.

This repo is split into branches, each representing a part in the series:

- [Part 0 - Beginning of the Project](https://github.com/jcolemorrison/getting-into-consul/tree/part-0)
- [Part 1 - Configuring Server and Client on AWS](https://github.com/jcolemorrison/getting-into-consul/tree/part-1)
- [Part 2 - Configuring Service Discovery for Consul on AWS](https://github.com/jcolemorrison/getting-into-consul/tree/part-2)
- [Part 3 - Scaling, Outage Recovery, and Metrics for Consul on AWS](https://github.com/jcolemorrison/getting-into-consul/tree/part-3)
- [Part 4 - Security, Traffice Encryption, and ACLs](https://github.com/jcolemorrison/getting-into-consul/tree/part-4)
- [Part 5 - All About Access Control Lists (ACLs)](https://github.com/jcolemorrison/getting-into-consul/tree/part-5)
- [Part 6a - Configuring Consul with HCP Vault and Auto-Config](https://github.com/jcolemorrison/getting-into-consul/tree/part-6)
- [Part 6b - Mostly Manual Configuration for Part-7 and beyond (use this)](https://github.com/jcolemorrison/getting-into-consul/tree/part-6-manual)
- [Part 7 - Enabling Consul Service Mesh](https://github.com/jcolemorrison/getting-into-consul/tree/part-7)
- [Part 8 - Traffic Shaping and Envoy Debugging](https://github.com/jcolemorrison/getting-into-consul/tree/part-8)
- [Part 9 - Metrics with Prometheus](https://github.com/jcolemorrison/getting-into-consul/tree/part-9)
- [Part 10 - Terminating and Ingress Gateways](https://github.com/jcolemorrison/getting-into-consul/tree/part-10)**
- [Part 11 - Mesh Federation](https://github.com/jcolemorrison/getting-into-consul/tree/part-11)**
- **[Master - The most up-to-date version of the repo](https://github.com/jcolemorrison/getting-into-consul)**

## The Architecture So Far:

![Getting into Consul Infrastructure](docs/getting-into-consul-part-9.png)

## Getting Started

To set use this repo, take the following steps:

1. Have an AWS Account.

2. Ensure you have the following things installed locally:
	- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
	- [Terraform](https://www.terraform.io/downloads.html)
	- [Consul](https://www.consul.io/downloads)
	- [jq](https://stedolan.github.io/jq/download/)

3. Either use the root user for your account, or create a new IAM user with either [Admin or PowerUser](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_job-functions.html#jf_developer-power-user) permissions.

4. Set up AWS credentials locally either through environment variables, through the AWS CLI, or directly in `~/.aws/credentials` and `~/.aws/config`.  [More information on authenticating with AWS for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).

5. Create an EC2 Keypair, download the key, and add the private key identity to the auth agent.  [More information on creating an EC2 Keypair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).

	```sh
	# After downloading the key from AWS, on Mac for example
	chmod 400 ~/Downloads/your_aws_ec2_key.pem

	# Optionally move it to another directory
	mv ~/Downloads/your_aws_ec2_key.pem ~/.ssh/

	# Add the key to your auth agent
	ssh-add -k ~/.ssh/your_aws_ec2_key.pem
	```

6. Create a `terraform.tfvars` file and add the name of your key for the `ec2_key_pair_name` variable:

	```
	ec2_key_pair_name = "your_aws_ec2_key"
	```

7. Run `terraform apply`!

8. After the apply is complete, run the post apply script:
	```sh
	# this will output two things:

	# 1. Sensitive values needed in a local file 'tokens.txt'

	# 2. Values required by the metrics_module

	# 3. Detailed setup instructions which are also listed below
	bash scripts/post-apply.sh
	```

9. SSH into `bastion` and then into your `getting-into-consul-mesh-gateway` node...
	1. Add the `mesh_gateway_node_id_token` from `tokens.txt` to the `/etc/consul.d/consul.hcl` file in the acl.tokens block.
	2. Add the `mesh_gateway_service_token` from `tokens.txt` to the `/etc/consul.d/tokens/gateway`.
	3. Restart both `consul` and `consul-envoy` service:
       ```sh
       sudo systemctl daemon-reload
       sudo systemctl restart consul consul-envoy
       ```

10. Create an ACL replication token. You need to allow ACL replication in connected secondary datacenters.
	```sh
	# this will output two things:

	# 1. Sensitive values needed in a local file 'tokens-acl.txt'

	# 2. Values required by the metrics_module

	# 3. Detailed setup instructions which are also listed below
	bash scripts/post-apply-acl.sh
	```

10. SSH into `bastion-dc2` and then into your `getting-into-consul-server-dc2` node...
    1. Add the `acl_replication_token` from `tokens-acl.txt` to the `/etc/consul.d/consul.hcl` file.
	1. Restart `consul` service.
	   ```sh
	   sudo systemctl restart consul
	   ```

11. Run the post apply script for `dc2`:

	```sh
	# this will output two things:

	# 1. Sensitive values needed in a local file 'tokens-dc2.txt'

	# 2. Values required by the metrics_module

	# 3. Detailed setup instructions which are also listed below
	bash scripts/post-apply-dc2.sh
	```

12. SSH into `bastion-dc2` and then into your `getting-into-consul-mesh-gateway-dc2` node...
	1. Add the `mesh_gateway_node_id_token` from `tokens-dc2.txt` to the `/etc/consul.d/consul.hcl` file in the acl.tokens block.
	2. Add the `mesh_gateway_service_token` from `tokens.txt` to the `/etc/consul.d/tokens/gateway`.
	3. Restart both `consul` and `consul-envoy` service:
       ```sh
       sudo systemctl daemon-reload
       sudo systemctl restart consul consul-envoy
       ```

13. After a few minutes, the two datacenters will have federated. You should be able to go into either Consul server in each datacenter...
    1. Check that the clusters have federated.
       ```sh
       $ export CONSUL_HTTP_TOKEN=<bootstrap token>

       $ consul members -wan

       Node                 Address            Status  Type    Build   Protocol  DC   Partition  Segment
       ip-10-254-2-250.dc2  10.254.2.250:8302  alive   server  1.11.3  2         dc2  default    <all>
       ip-10-255-2-250.dc1  10.255.2.250:8302  alive   server  1.11.3  2         dc1  default    <all>
       ```
	1. Check that in each datacenter can read the other's services.
	   ```sh
	   ## From dc1
	   $ curl -H "X-Consul-Token:${CONSUL_HTTP_TOKEN}" localhost:8500/v1/catalog/services?dc=dc2

	   ## From dc2
	   $ curl -H "X-Consul-Token:${CONSUL_HTTP_TOKEN}" localhost:8500/v1/catalog/services?dc=dc1
	   ```

14. SSH into `bastion` and then into your `getting-into-consul-api` nodes...
	1. Add the `client_api_node_id_token` from `tokens.txt` to the `/etc/consul.d/consul.hcl` file in the acl.tokens block.
	2. Add the `client_api_service_token` from `tokens.txt` to the `/etc/consul.d/api.hcl` file in the service.token block.
	3. Add the `client_api_service_token` from `tokens.txt` to the `/etc/systemd/system/consul-envoy.service`.
	4. Restart both `consul`, `api`, and `consul-envoy` service:
       ```sh
       sudo systemctl daemon-reload
       sudo systemctl restart consul api consul-envoy
       ```

15. SSH into `bastion` and then into your `getting-into-consul-web` nodes...
	1. Add the `client_web_node_id_token` from `tokens.txt` to the `/etc/consul.d/consul.hcl` file in the acl.tokens block.
	2. Add the `client_web_service_token` from `tokens.txt` to the `/etc/consul.d/web.hcl` file in the service.token block.
	3. Add the `client_web_service_token` from `tokens.txt` to the `/etc/systemd/system/consul-envoy.service`.
	4. Restart both `consul`, `web`, and `consul-envoy` service:
		```sh
       sudo systemctl daemon-reload
       sudo systemctl restart consul web consul-envoy
		```

16. SSH into `bastion-dc2` and then into your `getting-into-consul-api-2` nodes...
	1. Add the `client_api_dc2_node_id_token` from `tokens.txt` to the `/etc/consul.d/consul.hcl` file in the acl.tokens block.
	2. Add the `client_api_dc2_service_token` from `tokens.txt` to the `/etc/consul.d/api.hcl` file in the service.token block.
	3. Add the `client_api_dc2_service_token` from `tokens.txt` to the `/etc/systemd/system/consul-envoy.service`.
	4. Restart both `consul`, `api`, and `consul-envoy` service:
       ```sh
       sudo systemctl daemon-reload
       sudo systemctl restart consul api consul-envoy
       ```

> NOTE: On steps 14-16: sometimes `consul-envoy` will fail to start if `consul` isn't given enough time to start up.  Simply restart `consul-envoy` again if this is the case.

14. Head to the Consul UI via your `consul_server` output from Terraform (the `application load balancer` DNS for the server).
	1. Login with your root token (the `consul_token` output, you can find it in your state file)

15. To verify everything is working, check out your Consul UI...
	- All services in the **Services** tab should be green.
	- All nodes in the **Nodes** tab should be green.

16. To verify the web service is up and running, head to the DNS printed in the terraform output as `web_server`
	- It should show the upstream `body` of the `api` server with an IP address in `dc1`.

11. Run the post apply script to create a `service-resolver` that diverts all traffic from
    `web` to `api` in `dc2`.

	```sh
	# this will output two things:

	# 1. Sensitive values needed in a local file 'tokens-dc2.txt'

	# 2. Values required by the metrics_module

	# 3. Detailed setup instructions which are also listed below
	bash scripts/post-apply-resolver.sh
	```

### Setting Things Up Manually

Although this repo is set up so that you can get everything working via `terraform apply`, if you'd like to take the manual steps for learning, you can reference these documents:

1. [From Part 1 to Part 2 Manual Steps](part-2-manual-steps.md)
2. [From Part 2 to Part 3 Manual Steps](part-3-manual-steps.md)
3. [From Part 3 to Part 4 Manual Steps](part-4-manual-steps.md)
4. [From Part 4 to Part 5 Manual Steps](part-5-manual-steps.md)
5. Follow the Steps on this README to get to Part 6
6. [From Part 6 to Part 7 Manual Steps](part-7-manual-steps.md)
7. [From Part 7 to Part 8 Manual Steps](part-8-manual-steps.md)
8. [From Part 8 to Part 9 Manual Steps](part-9-manual-steps.md)
	- Checkout the [part-9-manual branch](https://github.com/jcolemorrison/getting-into-consul/tree/part-9-manual) to follow these.
9. [From Part 9 to Part 10 Manual Steps](part-10-manual-steps.md)

For example, if you wanted to manually learn Part 1 to Part 2, begin on the [Part 1 Branch](https://github.com/jcolemorrison/getting-into-consul/tree/part-1), and follow the "[From Part 1 to Part 2 Manual Steps](part-2-manual-steps.md)".

## Troubleshooting

#### `502 Bad Gateway Error` when visiting the Consul Server UI

The most likely cause of this is a failure to fetch and install consul on the servers due to a failure to get the required GPG key.  The most straightforward way to fix this is to `terraform destroy` the infrastructure and reapply it via `terraform apply`.

## Notes

- [Cloud Auto-Join](https://www.consul.io/docs/install/cloud-auto-join) is set up for part 1, despite not being in the stream itself.
