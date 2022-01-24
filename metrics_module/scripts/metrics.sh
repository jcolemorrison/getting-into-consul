#!/bin/bash

PROMETHEUS_VERSION="2.32.1"

# Install Prometheus
curl -fsSL -o prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz  https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar -xvf prometheus-${VERSION}.linux-amd64.tar.gz
mv prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz/prometheus /usr/bin/prometheus
chmod +x /usr/bin/prometheus

mkdir -p /etc/prometheus

# Create Prometheus Config File
cat > /etc/prometheus/prometheus.yaml <<- EOF
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
      - server: ${CONSUL_SERVER_IP}:8500
        token: ${CONSUL_ACL_TOKEN}
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
EOF

cat > /etc/systemd/system/prometheus.service <<- EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/prometheus/prometheus.yaml

[Service]
Type=simple
ExecStart=/usr/bin/prometheus --config.file /etc/prometheus/prometheus.yaml

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus