# Manual Beginning to End for Part-7

In order to begin the manual steps for this part, FIRST follow the [steps from part-6b's README.md](https://github.com/jcolemorrison/getting-into-consul/tree/part-6-manual) to completion.  This includes running the `post-apply.sh` script after running a `terraform apply`.  This will get the NON-service-mesh consul cluster, server, and clients all up and running.

_Note: If you're looking part-6 manual instructions, those are just the [README](https://github.com/jcolemorrison/getting-into-consul/tree/part-6-manual) on the part-6-manual branch._

## 1 - Update the Consul Server

1. SSH into your Bastion server

  ```
  ssh -A ubuntu@<bastion_ip>
  ```

2. SSH into your Consul Server

  ```
  ssh ubuntu@<consul_server_private_ip>
  ```

3. Open up the `/etc/consul.d/consul.hcl` and add the following to the bottom of the file:

  ```hcl
  # Below is what's required for service mesh
  ports {
    grpc = 8502
  }

  connect {
    enabled = true
  }

  # these are the default settings used for the proxies
  # the equivalent for services is `service-defaults` in the `kind` argument
  config_entries {
    bootstrap = [
      {
        kind = "proxy-defaults"
        name = "global"
        config {
          protocol                   = "http"
        }
      }
    ]
  }
  ```

4. Restart consul on the server:

  ```
  sudo systemctl restart consul
  ```

## 2 - Update the Consul API

1. SSH into your Bastion server

  ```
  ssh -A ubuntu@<bastion_ip>
  ```

2. SSH into your Consul API Client

  ```
  ssh ubuntu@<consul_api_client_private_ip>
  ```

3. Install [func-e](https://func-e.io/):

  ```sh
  curl https://func-e.io/install.sh | bash -s -- -b /usr/local/bin

  # install a consul supported version of envoy
  func-e use 1.21.2

  # make the bin available
  cp /root/.func-e/versions/1.21.2/bin/envoy /usr/local/bin/
  ```

4. Open the `/etc/consul.d/consul.hcl` file and add the following to the end:

  ```sh
  ports {
    grpc = 8502
  }
  ```
  - yes, that's really all you need to add

5. Open the `/etc/consul.d/api.hcl` file and add the following under the `check` block:

  ```hcl
  # this should be nested in the "service" block under the "check" block
  connect {
    sidecar_service {
      port = 20000
      check {
        name     = "Connect Envoy Sidecar"
        tcp      = "127.0.0.1:20000"
        interval = "10s"
      }
    }
  }
  ```
  - you can reference the [client-api.sh script](https://github.com/jcolemorrison/getting-into-consul/blob/part-7/scripts/client-api.sh#L121-L130).

6. Create a new file at `/etc/systemd/system/consul-envoy.service` and input the following:

  ```
  [Unit]
  Description=Consul Envoy
  After=syslog.target network.target

  # Put api service token here for the -token option!
  [Service]
  ExecStart=/usr/bin/consul connect envoy -sidecar-for=api -token=api_service_token
  ExecStop=/bin/sleep 5
  Restart=always

  [Install]
  WantedBy=multi-user.target
  ```
  - be sure to replace `api_service_token` with your `client_api_service_token` from `tokens.txt`!

7. Restart `consul` and `api` and start `consul-envoy`:

  ```
  sudo systemctl daemon-reload
  sudo systemctl restart consul
  sudo systemctl restart api
  sudo systemctl start consul-envoy
  ```
  - in the event that `consul-envoy` fails, restart it with `systemctl restart consul-envoy`.

## 3 - Update the Consul Web

1. SSH into your Bastion server

  ```
  ssh -A ubuntu@<bastion_ip>
  ```

2. SSH into your Consul Web Client

  ```
  ssh ubuntu@<consul_web_client_private_ip>
  ```

3. Install [func-e](https://func-e.io/):

  ```sh
  curl https://func-e.io/install.sh | bash -s -- -b /usr/local/bin

  # install a consul supported version of envoy
  func-e use 1.21.2

  # make the bin available
  cp /root/.func-e/versions/1.21.2/bin/envoy /usr/local/bin/
  ```

4. Open the `/etc/consul.d/consul.hcl` file and add the following to the end:

  ```sh
  ports {
    grpc = 8502
  }
  ```

5. Open the `/etc/consul.d/web.hcl` file and add the following under the `check` block:

  ```
  connect {
    sidecar_service {
      port = 20000
      check {
        name     = "Connect Envoy Sidecar"
        tcp      = "127.0.0.1:20000"
        interval = "10s"
      }
      proxy {
        upstreams {
          destination_name   = "api"
          local_bind_address = "127.0.0.1"
          local_bind_port    = 9091
        }
      }
    }
  }
  ```
  - you can reference the [client-web.sh script](https://github.com/jcolemorrison/getting-into-consul/blob/part-7/scripts/client-web.sh#L122-L138).

6. Open the `/etc/systemd/system/web.service` file and modify the `UPSTREAM_URIS` as follows:

  ```
  [Unit]
  Description=WEB
  After=syslog.target network.target

  [Service]
  Environment="MESSAGE=Hello from Web"
  Environment="NAME=web"
  Environment="UPSTREAM_URIS=http://127.0.0.1:9091"
  ExecStart=/usr/local/bin/fake-service
  ExecStop=/bin/sleep 5
  Restart=always

  [Install]
  WantedBy=multi-user.target
  ```
  - the difference is the `http://127.0.0.1:9091` value

7. Create a new file at `/etc/systemd/system/consul-envoy.service` and input the following:

  ```
  [Unit]
  Description=Consul Envoy
  After=syslog.target network.target

  # Put web service token here for the -token option!
  [Service]
  ExecStart=/usr/bin/consul connect envoy -sidecar-for=web -token=web_service_token
  ExecStop=/bin/sleep 5
  Restart=always

  [Install]
  WantedBy=multi-user.target
  ```
  - be sure to replace `web_service_token` with your `client_web_service_token` from `tokens.txt`!

8. Restart `consul` and `web` and start `consul-envoy`:

  ```
  sudo systemctl daemon-reload
  sudo systemctl restart consul
  sudo systemctl restart web
  sudo systemctl start consul-envoy
  ```
  - in the event that `consul-envoy` fails, restart it with `systemctl restart consul-envoy`.

## 4 - Setup Consul Intention

THis is to allow traffic between `api` and `web` via service mesh.

Head to the Consul UI via your `consul_server` output from Terraform (the `application load balancer` DNS for the server).

1. Login with your root token (the `consul_token` output, you can find it in your state file)

2. Head to **Intentions**.

3. Click **Create**.

4. For **Source**, select `web`.

5. For **Destination**, select `api`.

6. For source connection to destination, select `Allow`.

7. Click **Save**.

## 5 - Check Everything

1. To verify everything is working, check out your Consul UI...
	- All services in the **Services** tab should be green.
	- All nodes in the **Nodes** tab should be green.

2. To verify the web service is up and running, head to the DNS printed in the terraform output as `web_server`
	- It shouldn't have any errors