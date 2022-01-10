# Manual Beginning to End for Part-8

## Prerequisites

All of the below have been done to help consul differentiate between the `api-v1` and "newer" `api-v2` service.  We have two to deal with the fictional scenario of upgrading our API and wanting to progressively move our traffic to the newer version.

1. Open up the [`server.sh`](https://github.com/jcolemorrison/getting-into-consul/blob/part-8/scripts/server.sh#L93-L151) and remove lines 93 through 151.  This removes the `service-resolver`, `service-splitter`, and `service-router` so that you can make them on your own.

2. Follow the steps found in [Part 8 README's Getting Started](https://github.com/jcolemorrison/getting-into-consul/tree/part-8#getting-started) section to completion **up to step 15**.  This will put everything in place so that you can manually create the [Consul Configuration Entries](https://www.consul.io/docs/connect/config-entries).

3. Take note of some changes:
  - An [additional auto-scaling group](https://github.com/jcolemorrison/getting-into-consul/blob/part-8/ec2-asg.tf#L159-L207) and [launch template](https://github.com/jcolemorrison/getting-into-consul/blob/part-8/ec2-launch-templates.tf#L147-L189) have been to represent a `v2` of the `api`.
  - An additional [`client-api-v2.sh`](https://github.com/jcolemorrison/getting-into-consul/blob/part-8/scripts/client-api-v2.sh) script has been added to bootstrap the new servers.  It's largely identical to `client-api.sh`, with IDs and labels updated with a `v2` identifier where needed.
  - In both the `client-api.sh` and `client-api-v2.sh` files, the `/etc/consul.d/api.hcl` the services have had their `ID` changed to either [`api-v1`](https://github.com/jcolemorrison/getting-into-consul/blob/part-8/scripts/client-api.sh#L110) or [`api-v2`](https://github.com/jcolemorrison/getting-into-consul/blob/part-8/scripts/client-api-v2.sh#L110) respectively.  Also, the services have been given a `meta.version` block with a [`v1`](https://github.com/jcolemorrison/getting-into-consul/blob/part-8/scripts/client-api.sh#L122-L124) or [`v2`](https://github.com/jcolemorrison/getting-into-consul/blob/part-8/scripts/client-api-v2.sh#L122-L124) value respectively.
  - In both the `client-api.sh` and `client-api-v2.sh` files, the `/etc/systemd/system/consul-envoy.service` files have had their `-sidecar-for` flag updated with either [`api-v1`](https://github.com/jcolemorrison/getting-into-consul/blob/part-8/scripts/client-api.sh#L148) or [`api-v2`](https://github.com/jcolemorrison/getting-into-consul/blob/part-8/scripts/client-api-v2.sh#L148) respectively.

4. SSH into your Bastion Server and then into your `getting-into-consul-server`.  This is your beginning point.

## 1 - Create the Consul `service-resolver`

A Consul [`service resolver`](https://www.consul.io/docs/connect/config-entries/service-resolver) allows you to take one common service, aka `api`, that may have different versions, and then split it into recognizable "subsets".  This way you can then begin using the service-router and service-splitter (that we'll make later) to ... route and split traffic.

1. Double check that you're on the `getting-into-consul-server`.

2. Set your `CONSUL_HTTP_TOKEN` to the value of your `consul_token` in your Terraform output.  Since this was marked as a sensitive value, you'll have to open up your `terraform.tfstate` file and get it.
  - this is so you can interact with Consul as the root and set the configuration entries.

  ```sh
  export CONSUL_HTTP_TOKEN=<consul_token>
  ```

3. Create a new file `service-resolver.hcl` and input the following contents:

  ```hcl
  Kind          = "service-resolver"
  Name          = "api"
  DefaultSubset = "v1"
  Subsets = {
    v1 = {
      Filter = "Service.Meta.version == v1"
    }
    v2 = {
      Filter = "Service.Meta.version == v2"
    }
  }
  ```
  
4. Apply the file via `consul`'s CLI:

  ```
  consul config write service-resolver.hcl
  ```

5. Head to the Consul UI via your `consul_server` output from Terraform (the `application load balancer` DNS for the server).
  1. Login with your root token (the `consul_token` output, you can find it in your state file)

6. To verify that the Consul `service-resolver` has been created to differentiate between `api` and `api-v2`:
  1. Head to **Services**.
  2. Select the `api` service.
  3. Click on the **Routing** tab.
  4. Confirm that within the **Resolvers** box, you see `v1` and `v2` as resolvers.

## 2 - Create the Consul `service-splitter`

This [`service splitter`](https://www.consul.io/docs/connect/config-entries/service-splitter) is how we split the traffic based on weight.  Note that the `Name` property here IS referring to the NAME of the service.  So the `Name` of services in Consul serve as an umbrella for subsets.  However, the `ID` is the true identifier.

1. Ensure steps #1 and #2 from the previous section are done.  (You're on the server and have the token set).

2. Create a new file `service-splitter.hcl` and input the following contents:

  ```hcl
  Kind = "service-splitter"
  Name = "api"
  Splits = [
    {
      Weight        = 90
      ServiceSubset = "v1"
    },
    {
      Weight        = 10
      ServiceSubset = "v2"
    },
  ]
  ```

3. Apply the file via `consul`'s CLI:

  ```
  consul config write service-splitter.hcl
  ```

4. Head to the Consul UI via your `consul_server` output from Terraform (the `application load balancer` DNS for the server).
  1. Login with your root token (the `consul_token` output, you can find it in your state file)

5. To verify that the Consul `service-resolver` has been created to differentiate between `api` and `api-v2`:
  1. Head to **Services**.
  2. Select the `api` service.
  3. Click on the **Routing** tab.
  4. Confirm that within the **Resolvers** box, you see `v1` and `v2` as resolvers.
  5. Hover over the connecting lines to see the traffic split percentages from the `service-splitter`.

## 3 - Create the Consul `service-router`

The [`service router`](https://www.consul.io/docs/connect/config-entries/service-router) allows you to route to specific paths of services and service SUBSETS. This is how we go beyond intentions and make it so that you can route to things based on paths, headers, etc. Only works for connections via proxy though, meaning that, unless you configure your load balancer to carry headers through, they'd get lost.

1. Ensure steps #1 and #2 from the first section are done.  (You're on the server and have the token set).

2. Create a new file called `service-router.hcl` and input the following contents:

  ```hcl
  Kind = "service-router"
  Name = "api"
  Routes = [
    {
      Match {
        HTTP {
          Header = [
            {
              Name  = "x-debug"
              Exact = "1"
            },
          ]
        }
      }
      Destination {
        Service       = "api"
        ServiceSubset = "v2"
      }
    }
  ]
  ```

3. Apply the file via `consul`'s CLI:

  ```
  consul config write service-router.hcl
  ```

4. Head to the Consul UI via your `consul_server` output from Terraform (the `application load balancer` DNS for the server).
  1. Login with your root token (the `consul_token` output, you can find it in your state file)

5. To verify that the Consul `service-router` has been created to split the traffic:
  1. Head to **Services**.
  2. Select the `api` service.
  3. Click on the **Routing** tab.
  4. Confirm that an **API Router** box exists that sends any traffic with the `x-debug: 1` header to `v2`.

6. (Optional) SSH from your bastion into the `getting-into-consul-web` server.  Run the following command:

  ```
  curl -H "X-Debug: 1" localhost:9091
  ```
  - the `body` field should be `apiv2`