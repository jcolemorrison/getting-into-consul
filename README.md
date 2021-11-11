# Getting into Consul

This is the repo used in the [Getting into HashiCorp Consul](https://www.youtube.com/playlist?list=PL81sUbsFNc5b8i2g2sB_tG-PuZxEdlDpK) series where we walk through building out a Consul based architecture and cluster, on AWS, from scratch.

This repo is split into branches, each representing a part in the series:

- [Part 1 - Configuring Server and Client on AWS](https://github.com/jcolemorrison/getting-into-consul/tree/part-1)
- [Part 2 - Configuring Service Discovery for Consul on AWS](https://github.com/jcolemorrison/getting-into-consul/tree/part-2)
- [Part 3 - Scaling, Outage Recovery, and Metrics for Consul on AWS](https://github.com/jcolemorrison/getting-into-consul/tree/part-3)
- [Part 4 - Security, Traffice Encryption, and ACLs](https://github.com/jcolemorrison/getting-into-consul/tree/part-4)
- [Part 5 - All About Access Control Lists (ACLs)](https://github.com/jcolemorrison/getting-into-consul/tree/part-5)
- **[Part 6a - Configuring Consul with HCP Vault and Auto-Config](https://github.com/jcolemorrison/getting-into-consul/tree/part-6)**
- [Part 6b - Mostly Manual Configuration for Part-7 and beyond (use this)](https://github.com/jcolemorrison/getting-into-consul/tree/part-6-manual)
- [Master - The most up-to-date version of the repo](https://github.com/jcolemorrison/getting-into-consul)

## NOTE - Use this [Part 6 branch](https://github.com/jcolemorrison/getting-into-consul/tree/part-6-manual) to follow along

Although this branch uses HCP Vault and Consul's Auto Config feature, it winds up requiring more work to bootstrap the entire cluster.  We also didn't want to require HCP Vault in the series.  Furthermore, we wound up implementing consul connect to get this functionality before we covered it in the series.  Therefore, we moved back to using the workflow without HCP Vault or Auto Config.

Finally, this branch is missing a few things to make it work that will be added at a later date.

## The Architecture So Far:

![Getting into Consul Infrastructure](docs/getting-into-consul-part-3.png)

## Getting Started

To set use this repo, take the following steps:

1. Have an AWS Account.

2. Either use the root user for your account, or create a new IAM user with either [Admin or PowerUser](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_job-functions.html#jf_developer-power-user) permissions.

3. Set up AWS credentials locally either through environment variables, through the AWS CLI, or directly in `~/.aws/credentials` and `~/.aws/config`.  [More information on authenticating with AWS for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).

4. Create an EC2 Keypair, download the key, and add the private key identity to the auth agent.  [More information on creating an EC2 Keypair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).

		```sh
		# After downloading the key from AWS, on Mac for example
		chmod 400 ~/Downloads/your_aws_ec2_key.pem
		
		# Optionally move it to another directory
		mv ~/Downloads/your_aws_ec2_key.pem ~/.ssh/

		# Add the key to your auth agent
		ssh-add -k ~/.ssh/your_aws_ec2_key.pem
		```

5. Create a `terraform.tfvars` file and add the name of your key for the `ec2_key_pair_name` variable:

		```
		ec2_key_pair_name = "your_aws_ec2_key"
		```

6. Run `terraform apply`!

7. Follow [Part 4's instructions on setting up ACLs](part-4-manual-steps.md#part-3---secure-consul-with-access-control-lists-acls).
	- automation for this coming later...

8. Follow [Part 5's Instructions on completing the ACL setup](part-5-manual-steps.md#enabling-communication-between-web-and-api-with-acls).

9. To check out your Consul UI...
	- Go to the **EC2 Console**.
	- Select **Load Balancers**.
	- Select the load balancer created for our project, and grab its DNS.
	- Navigate to the DNS.

### Setting Things Up Manually

Although this repo is set up so that you can get everything working via `terraform apply`, if you'd like to take the manual steps for learning, you can reference these documents:

1. [From Part 1 to Part 2 Manual Steps](part-2-manual-steps.md)
2. [From Part 2 to Part 3 Manual Steps](part-3-manual-steps.md)
3. [From Part 3 to Part 4 Manual Steps](part-4-manual-steps.md)
4. [From Part 4 to Part 5 Manual Steps](part-4-manual-steps.md)

For example, if you wanted to manually learn Part 1 to Part 2, begin on the [Part 1 Branch](https://github.com/jcolemorrison/getting-into-consul/tree/part-1), and follow the "[From Part 1 to Part 2 Manual Steps](part-2-manual-steps.md)".

### For Part 4

In order to follow along beyond part 4, for now, you'll need to follow the instructions in the [Part 4 Manual Steps](part-4-manual-steps.md) for setting up ACLs.  Automation will be added later for that.

### Notes

- [Cloud Auto-Join](https://www.consul.io/docs/install/cloud-auto-join) is set up for part 1, despite not being in the stream itself.
