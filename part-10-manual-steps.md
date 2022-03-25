# Manual Beginning to End for Part-10

## Prerequisites

In between part-9 and part-10 the following resources were added:

- Launch Templates, Auto Scaling Groups, Security Groups, TLS certificates, and setup scripts for the `terminating gateway`
- Launch Templates, Auto Scaling Groups, Security Groups, TLS certificates, Load Balancer, and setup scripts for the `ingress gateway`
- EC2 instance, security groups, and setup scripts for a "database"
- An additional VPC

The VPC and Database were added to serve as an "external" service that our mesh connects to using Terminating gateways.

Though it seems like a lot of resources, conceptually, not much is new for these additional resources.  They use many of the same settings as the `client api` and `client web` services.

Additionally, to recreate the manual steps you'll need to remove (or comment out) some lines within the exiting code.

1. In `scripts/server.sh` remove (or comment out) lines 104-106.

2. In `scripts/server.sh` remove (or comment out) lines 119-146.

3. In `scripts/post-apply.sh` remove (or comment out) lines 122-139.

## Manual Steps

### Terminating Gateway

1. Follow the README instructions all the way to step #13.

2. SSH into your `getting-into-consul-terminating-gateway` server.

3. Set a `CONSUL_HTTP_TOKEN` environment variable value of your `consul_token` in your Terraform output.  Since this was marked as a sensitive value, you'll have to open up your `terraform.tfstate` file and get it.
  - this is so you can interact with Consul as the root and set the configuration entries.

  ```sh
  export CONSUL_HTTP_TOKEN=<consul_token>
  ```

4. Create the "database" service file that will serve as the pointer to the external database that exists in our external subnet:

  ```sh
  cat > database.json <<- EOF
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
  ```
  - DB_HOSTNAME is the `hostname` of your database instance.  You can find this in the EC2 consul on your `getting-into-consul-database` instance under the label **Hostname type**.  You'll remove the `.ec2.internal` portion of that value.  (i.e. if Hostname type is `ip-01-123-4-567.ec2.internal` then the `hostname` is `ip-01-123-4-567`.)
  - DB_PRIVATE_IP is the `private IPv4 address` of the `getting-into-consul-database`.

5. Register the database service to consul:

  ```sh
  curl --request PUT -H "X-Consul-Token:$CONSUL_HTTP_TOKEN" --data @`pwd -P`/files/database.json "$CONSUL_HTTP_ADDR/v1/catalog/register"
  ```
  - `$CONSUL_HTTP_TOKEN` is the token you exported in step #3.
  - `$CONSUL_HTTP_ADDR` is the Application Load Balancer of your consul server.  This is output as `consul_server` in your terraform outputs.
  - We register it through the API because otherwise consul assumes that the database service is present on the current node.  This allows us to register it without that assumption.

6. Create the terminating gateway config file:

  ```sh
  cat > terminating-gateway.hcl <<- EOF
  {
    Kind = "terminating-gateway"
    Name = "tm"
    Services = [
      {
        Name = "database"
      }
    ]
  }
  EOF
  ```

7. Register the terminating gateway config:

  ```
  consul config write terminating-gateway.hcl
  ```

8. Check that the database is reachable by visiting your Web server's load balancer.
  - this is output as `web_server` in your terraform outputs.
  - you should see the database in the upstream calls payload.
  - you may need to restart `consul` and `consul-envoy`.

### Ingress Gateway

1. Follow the README instructions all the way to step #13.

2. SSH into your `getting-into-consul-ingress-gateway` server.

3. Set a `CONSUL_HTTP_TOKEN` environment variable value of your `consul_token` in your Terraform output.  Since this was marked as a sensitive value, you'll have to open up your `terraform.tfstate` file and get it.
  - this is so you can interact with Consul as the root and set the configuration entries.

  ```sh
  export CONSUL_HTTP_TOKEN=<consul_token>
  ```

4. Create the `ingress-gateway.hcl` config file:

  ```sh
  cat > ingress-gateway.hcl <<- EOF
  {
    Kind = "ingress-gateway"
    Name = "ig"

    Listeners = [
      {
        Port = 9090
        Protocol = "http"
        Services = [
          {
            Name = "api"
          },
          {
            Name = "web"
          }
        ]
      }
    ]
  }
  EOF
  ```

5. Register the ingress gateway:

  ```sh
  consul config write ingress-gateway.hcl
  ```

6. Confirm that you can reach the API directly by running the following on your local machine:

  ```sh
  curl -i -H "Host: api.ingress.consul" $YOUR_INGRESS_GATEWAY_ALB
  ```
  - `$YOUR_INGRESS_GATEWAY_ALB` is the DNS of your ingress gateway's application load balancer.  This is output as `ingress_gateway_dns` in your terraform outputs.