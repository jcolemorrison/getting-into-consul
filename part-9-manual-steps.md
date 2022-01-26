# Manual Beginning to End for Part-9

## Prerequisites

To complete the manual step-by-step for this part, FIRST, follow all instructions in this branch's [README.md](https://github.com/jcolemorrison/getting-into-consul/tree/part-9-manual).  This gets all of the servers up and ready so that we can scrape them for metrics.

In addition to the infrastructure for all consul things, a number of other resources have been added:

- Auto Scaling Group for the Metrics Server
- Launch Template for the Metrics Server
- Load Balancer, Rules, Target Group for the Metrics Server
- Security Group and Security Group Rules for the Metrics Server

These are what will be used to host Prometheus.

## 1 - Set Up The Consul Server

1. SSH into your `getting-into-consul-server` node.

2. Set a `CONSUL_HTTP_TOKEN` environment variable value of your `consul_token` in your Terraform output.  Since this was marked as a sensitive value, you'll have to open up your `terraform.tfstate` file and get it.
  - this is so you can interact with Consul as the root and set the configuration entries.

  ```sh
  export CONSUL_HTTP_TOKEN=<consul_token>
  ```

3. Create a new file `temp.hcl` and input the following contents:

  ```hcl
  Kind = "proxy-defaults"
  Name = "global"
  Config {
    protocol = "http"
    envoy_prometheus_bind_addr = "0.0.0.0:9102"
  }
  ```

4. Write the config file:

  ```sh
  consul config write temp.hcl
  ```

5. Double check that the changes persisted:

  ```sh
  consul config read -kind proxy-defaults -name global
  ```

## 2 - Set Up The Consul API Client

1. SSH into your `getting-into-consul-api` node.

2. Open up the `/etc/consul.d/consul.hcl` file and append the following contents to the bottom of the file:

  ```hcl
  telemetry {
    prometheus_retention_time = "24h"
    disable_hostname = true
  }
  ```

3. Restart Consul:

  ```
  sudo systemctl restart consul
  ```

## 3 - Set Up The Consul API v2 Client

(these instructions are the same as the previous, just for the `v2` node.)

1. SSH into your `getting-into-consul-api-v2` node.

2. Open up the `/etc/consul.d/consul.hcl` file and append the following contents to the bottom of the file:

  ```hcl
  telemetry {
    prometheus_retention_time = "24h"
    disable_hostname = true
  }
  ```

3. Restart Consul:

  ```
  sudo systemctl restart consul
  ```

## 4 - Set Up The Consul Web Client

(these instructions are the same as the previous, just for the `web` node.)

1. SSH into your `getting-into-consul-web` node.

2. Open up the `/etc/consul.d/consul.hcl` file and append the following contents to the bottom of the file:

  ```hcl
  telemetry {
    prometheus_retention_time = "24h"
    disable_hostname = true
  }
  ```

3. Restart Consul:

  ```
  sudo systemctl restart consul
  ```

## 5 - Set Up The Metrics Server

1. SSH into your `getting-into-consul-metrics` node.

2. Download and install [prometheus](https://prometheus.io/):

  ```sh
  curl -fsSL -o prometheus-2.32.1.linux-amd64.tar.gz https://github.com/prometheus/prometheus/releases/download/v2.32.1/prometheus-2.32.1.linux-amd64.tar.gz

  tar -xvf prometheus-2.32.1.linux-amd64.tar.gz

  mv prometheus-2.32.1.linux-amd64/prometheus /usr/bin/prometheus

  chmod +x /usr/bin/prometheus
  ```

3. Have two values on hand:
  - Your `consul_token` value from your `terraform.tfstate` file.
  - The `private IP address` of your Consul Server node.

4. Create a new file called `prometheus.yaml` and input the following contents:

  ```yaml
  # my global config
  global:
    scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
    evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
    # scrape_timeout is set to the global default (10s).

  # Alertmanager configuration
  alerting:
    alertmanagers:
      - static_configs:
          - targets:
            # - alertmanager:9093

  # Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
  rule_files:
    # - "first_rules.yml"
    # - "second_rules.yml"

  # A scrape configuration containing exactly one endpoint to scrape:
  # Here it's Prometheus itself.
  scrape_configs:
    # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
    - job_name: "prometheus"

      # metrics_path defaults to '/metrics'
      # scheme defaults to 'http'.

      static_configs:
        - targets: ["localhost:9090"]
    - job_name: 'envoy'
      consul_sd_configs:
        - server: <YOUR_CONSUL_SERVER_PRIVATE_IP>
          token: <YOUR_CONSUL_TOKEN>
          datacenter: dc1
          services:
            - "api"
            - "web"
      relabel_configs:
        - source_labels: [__meta_consul_address]
          regex: '(.*)'
          replacement: '${1}:9102'
          target_label: '__address__'
          action: 'replace'
  ```
  - Replace the `<YOUR_CONSUL_SERVER_PRIVATE_IP>` with your consul server's private IP address.
  - Replace `<YOUR_CONSUL_TOKEN>` with your `consul_token` value from your `terraform.tfstate` file.

5. Start prometheus:

  ```sh
  prometheus --config.file="prometheus.yaml"
  ```

6. Visit your metrics server by going to your metrics load balancer endpoint:
  1. Go to the EC2 console.
  2. Go to **Load Balancers**.
  3. Find the load balancer prefixed with `csulm-` and navigate to its DNS.