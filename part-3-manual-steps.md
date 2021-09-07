# Manual Beginning to End for Part-3

These are the manual instructions for the things covered in [Part 3](https://www.youtube.com/watch?v=_lIJg0c5les&list=PL81sUbsFNc5b8i2g2sB_tG-PuZxEdlDpK&index=3) of our ["Getting into Consul" series](https://www.youtube.com/watch?v=0H06VKvlTJQ&list=PL81sUbsFNc5b8i2g2sB_tG-PuZxEdlDpK).  In this part we covered three things:

1. [Health Checks and Hot Reloading with Consul for the Clients](#1---health-checks-and-hot-reloading-with-consul-for-the-clients)
2. [Scaling Consul Infrastructure on AWS](#2---scaling-consul-infrastructure-on-aws)
3. [Dealing with Outages](#3---dealing-with-outages)
4. [Setting up Telemetry and Metrics](#4---setting-up-telemetry-and-metrics)

In this document, we'll walk through the manual steps required to get through part 3 if you'd rather take that approach over using the automated script.  The instructions will be sparse in description.  If you need more depth and reasoning behind why we did things, checkout the [video](https://www.youtube.com/watch?v=_lIJg0c5les)!

## 1 - Health Checks and Hot Reloading with Consul for the Clients

The first thing we explored was setting up health checks for our `api` and `web` services present on our Consul Clients.  On each client perform the following steps.  The process will be the same for both `api` and `web`, so we'll only put the instructions for one:

1. SSH into the bastion instance:

```sh
# assuming you have your ec2 keypair on your ssh agent
ssh -A ubuntu@<bastion_ip>
```

2. SSH from the bastion into the `api` server.

```sh
ssh ubuntu@<consul_client_api_private_ip>
```

3. Modify the file at `/etc/consul.d/api.hcl` to reflect the following:

```hcl
service {
  name = "api"
  port = 9090

  check {
    id = "api"
    name = "HTTP API on Port 9090"
    http = "http://localhost:9090/health"
    interval = "30s"
  }
}
```

4. Reload Consul:

```sh
consul reload
```

5. Check out the UI by going to our Application Load Balancer's DNS.  Find this by going to the AWS Console > EC2 Console > Load Balancers > Selecting our Load Balancer with the prefix `csul` > grab the DNS > navigate to it in your browser.

6. Optionally do the same for your `web` service.  You'd repeat steps 1-5, except you'd ssh into the Consul Client Web server and use the following for the `/etc/consul.d/web.hcl` file:

```hcl
service {
  name = "web"
  port = 9090

  check {
    id = "web"
    name = "HTTP Web on Port 9090"
    http = "http://localhost:9090/health"
    interval = "30s"
  }
}
```

### Registering a New Service

What if you want to register a new service to a Consul Client without stopping the server?

1. SSH into either of the Consul Clients.

2. Get the service up and running.
	- See [Part 2](https://github.com/jcolemorrison/getting-into-consul/tree/part-2) for instruction on how to do this with `systemd` and and [Fake Service](https://github.com/nicholasjackson/fake-service).
	- for purposes of this document, let's pretend you're new service is called `payments` and listens on port `9091`.

3. Create a new config file at `/etc/consul.d/payments.hcl` and input the following contents:

```hcl
service {
	name = "payments"
	port = 9090

	check {
		id = "payments"
		name = "HTTP Payments on Port 9091"
		http = "http://localhost:9091/health"
		interval = "30s"
	}
}
```

4. Reload Consul:

```
consul reload
```

5. Either check the Consul UI or run the following to see your new service live:

```
consul catalog services
```

6. To get rid of the service, delete the config file at `/etc/consul.d/payments.hcl` and run:

```
consul reload
```

## 2 - Scaling Consul Infrastructure on AWS

This part largely happened off the stream since it was AWS focused.  Because of this we opted to do this work in the background and leave the stream to dealing directly with scaling the number of servers up and down.  The following is what changed in the Terraform code between Part 2 and Part 3 to make the scaling possible:

1. Convert the EC2 [Instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) for the Consul Server into an AWS [Launch Template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) and [AutoScaling Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group).
	- The settings largely carry over, 1-to-1, from the instance to the Launch Template

2. Remove the [LB Target Group Attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) resource, because attaching instances created from AutoScaling Groups (ASG) to target groups is done within the ASG's [`target_group_arns`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) argument.

3. Add variables to control the desired number of servers in `variables.tf`. For each server and service there's three variables:
	- `<node>_desired_count`: the desired number of nodes
	- `<node>_min_count`: the minimum number of nodes
	- `<node>_max_count`: the max number of nodes
	- where `<node>` is either `server`, `client_web`, or `client_api`.

4. Change the values of the variables listed in the previous step and run `terraform apply` to scale them up or down.
	- **WARNING**: scaling down the `consul_server` autoscaling group may potentially lead to an outage. More information in the next section...
	- scaling up or down the `consul_client_web` or `consul_client_api` will not cause any issues.

5. Wait for the changes to apply, and then happily check your scaled-in or scaled-out services and servers.

For a more in-depth look at the change in files, [see the comparison](https://github.com/jcolemorrison/getting-into-consul/compare/part-2...part-3?expand=1).

## 3 - Dealing with Outages

This section deals with outages for Consul Servers.  Some context - all storage with respect to your Consul Cluster is kept within [Consul's KV store](https://www.consul.io/docs/dynamic-app-config/kv) and persisted via Raft.  In summary, data is kept on each server and then gossiped between servers until parity is achieved.  This means that if any one server goes down, the remaining servers should (hopefully) have the state.

One of the more problematic outages occurs when the [leader](https://www.consul.io/docs/architecture/consensus) of the servers goes down and the followers aren't given enough time to hold a new election.  When this occurs, there are manual steps that need to be taken when in order to recover your cluster.

### Simulating an Outage

1. Assuming your `var.server_desired_count` is `3` set it to `1` and apply the changes.
	- You can do this in Terraform or manually in the AWS Console
	- We'll call the remaining server the "survivor"

2. SSH into the survivor Consul Server and check its status:

```sh
sudo systemctl status consul
```
- you will more than likely find it complaining about there being "No Cluster Leader"

3. Stop the surivor server:

```sh
sudo systemctl stop consul
```

4. Create any new servers that will take the place of the ones that went down.
	- use the same configurations used in the other consul servers

5. Go through each of your servers, both the suriving server and the new servers and collect the following information:
	1. Get the value of the `node-id` found in the file at `/opt/consul/node-id`
	2. Get the `ip address` of each node
	3. Create a file, on the surviving server, at `/opt/consul/raft/peers.json` with the following information:
		```json
		[
			{
				"id": "node_id_of_surivor_server",
				"address": "<ip_of_survivor_server>:8300",
				"non_voter": false
			},
			{
				"id": "node_id_of_living_or_new_server",
				"address": "<ip_of_living_or_new_server>:8300",
				"non_voter": false
			},
			{
				"id": "node_id_of_living_or_new_server",
				"address": "<ip_of_living_or_new_server>:8300",
				"non_voter": false
			},
			... more here if you needed them.
		]
		```
		- where "survivor" is our server that did not get shut down, "living" is a server that went down but is still in existence, and "new" is a server that you stood up after the outage.
		- [more information on peers.json and outage recovery](https://learn.hashicorp.com/tutorials/consul/recovery-outage#manual-recovery-using-peers-json).

6. On any **existing** servers that experienced the outage, but that are still in existence do the following:
	1. Stop the consul server via `sudo systemctl stop consul`.
	2. Input the aforementioned `peers.json` file at `/opt/consul/raft/peers.json`.
	3. Do NOT restart the servers yet.

7. On any **new** servers started AFTER the outage stop the consul server via `sudo systemctl stop consul`.

8. Return to the **surviving** server and do the following:
	1. Start consul via `sudo systemctl start consul`.
	2. Run the following command to remove any dead servers: `consul operator autopilot state`.
	3. Check that the server has gone back up with `sudo systemctl status consul`.
		- `journalctl -u consul -f` can give more detailed logs
		- `consul operator raft list-peers` will show other fellow servers
	4. Note this server's private IP address.

9. On any **existing** servers, do the following:
	1. Start consul via `sudo systemctl start consul`.
	2. Run the following command to join the cluster:
		```
		consul join <suriving_server_private_ip>
		```

10. On any **new** servers, start consul via `sudo systemctl start consul`.

11. Upon running `consul operator raft list-peers`, you should see all of your other Consul Servers where one of them is the leader.  Your cluster should be working again!

## 4 - Setting up Telemetry and Metrics

This final section deals with setting up metrics and, compared to the previous sections, is short.

In order to pull metrics from your Consul Cluster, simply hit the following endpoint:

```sh
# where your_host is localhost, the node IP address, etc
curl <your_host>:8500/v1/agent/metrics

# pretty print it without jq
curl <your_host>:8500/v1/agent/metrics?pretty
```

In the event that you want to send metrics to [Prometheus](https://prometheus.io/) do the following **on each node you wanted monitored**:

1. Modify the consul configuration file at `/etc/consul.d/consul.hcl` to reflect the following:

```hcl
data_dir = "/opt/consul"

client_addr = "0.0.0.0"

ui_config{
  enabled = true
}
server = true

bind_addr = "0.0.0.0"

advertise_addr = "10.255.3.120"

bootstrap_expect=3

retry_join = ["provider=aws tag_key=\"Project\" tag_value=\"getting-into-consul\""]

telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}
```

2. Restart consul:

```
sudo systemctl restart consul
```

3. Point Prometheus to the `<your_host>:8500/v1/agent/metrics?format=prometheus` endpoint.

Note: not all things in `consul.hcl`, or consul config files in general, are hot reloadable via `consul reload`.  In this case the `telemetry` block is not, so consul must be completely restarted via `systemctl`.

Note: because we're not using Prometheus in the series at the moment, this block won't be added to the userdata script.