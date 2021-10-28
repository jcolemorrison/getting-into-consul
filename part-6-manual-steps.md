# Manual Beginning to End for Part-6

While auto-configuration alleviates the need to pass certificates
and ACL tokens between clients, you do need to set up JWT authentication
to allow hosts to self-register to the Consul server.

The Terraform configuration uses HCP Vault to issue JSON Web Tokens (JWT)
for each Consul client.

After running `terraform apply`, you must register the Consul clients as
follows.

## Generate JWT for Consul clients

You must generate a JWT with the node name of the Consul clients.
Retrieve the hostname of each Consul client.

1. Set the environment variables so you can access Vault.
   ```shell
   export VAULT_ADDR=<public HCP vault address>
   export VAULT_TOKEN=<HCP vault root token>
   export VAULT_NAMESPACE=admin
   ```

1. In your terminal, run `vault.sh`. This updates the issuer in HCP Vault.
   ```shell
   bash vault.sh
   ```

1. SSH into Consul server via the bastion and restart Consul.
   ```shell
   sudo systemctl restart consul
   ```

## Generate ACL tokens for services

You still need to generate ACL tokens for the services.

1. In your terminal, run `consul.sh`.
   ```shell
   bash consul.sh
   ```

1. This generates a file with the service tokens, `tokens.auto.tfvars`.

1. Taint the autoscaling groups for the web and api clients. This forces
   recreation of the instance.
   ```shell
   $ terraform taint aws_autoscaling_group.consul_client_web
   $ terraform taint aws_autoscaling_group.consul_client_api
   ```

1. Reapply Terraform.
   ```shell
   terraform apply
   ```

## Add JWT to Consul clients.

1. Set the environment variable `WEB_NODE_NAME` to the hostname
   of the web server.
   ```shell
   export WEB_NODE_NAME="ip-10-*-*-*"
   ```

1. Set the environment variable `API_NODE_NAME` to the hostname
   of the api server.
   ```shell
   export API_NODE_NAME="ip-10-*-*-*"
   ```

1. In your terminal, run `vault_oidc.sh`. This generates JWTs for api and web services.
   You'll find the JWT tokens for each node under the `tokens/` directory.
   ```shell
   bash vault_oidc.sh
   ```

1. Copy the JWT for the specific node under the `tokens/` directory.

1. SSH into each client and write the JWT for each node to `/etc/consul.d/jwt`.
   ```shell
   sudo echo '<JWT for node>' > /etc/consul.d/jwt
   ```

1. Restart Consul on the client.
   ```shell
   sudo systemctl restart consul
   ```