# Manual Beginning to End for Part-4

The process we followed is a bit more involved because we chose to add all of the security with the Consul Cluster live (as opposed to doing the configuration directly in Terraform).  Therefore, the process in some of these is a bit more involved.  Furthermore, the following is written _as if_ you're process is the same, which means that you've got the cluster up and running at the end ofo part 3.

## Part 1 - Securing Gossip Communication with Encryption

This process assumes your Consul cluster is live and sets up encryption.  However, since the cluster is live, you'll be doing a rolling update manually.

1. SSH into your `consul server`.

2. Generate a key using the `consul keygen` command:

```sh
consul keygen
```

This will output a key that you'll need to use on all Consul `servers` AND `clients`.  So...keep it secret, keep it safe.

3. Add the following to your `/etc/consul.d/consul.hcl` configuration file:

```hcl
encrypt = "your_key_from_consul_keygen_command"
encrypt_verify_incoming = false
encrypt_verify_outgoing = false
```

These should be added top level of the file, not nested in any blocks.

4. Restart Consul:

```
systemctl restart consul
```

5. Repeat #3 and #4 on all existing Consul `servers` and `clients`.

6. Return to your Consul server and update the `/etc/consul.d/consul.hcl` configuration file:

```hcl
encrypt = "your_key_from_consul_keygen_command"
encrypt_verify_incoming = false
encrypt_verify_outgoing = true # the only thing that changes
```

7. Restart Consul:

```
systemctl restart consul
```

8. Repeat steps #6 and #7 on all Consul `servers` and `clients`.

9. Return to your Consul server and update the `/etc/consul.d/consul.hcl` configuration file:

```hcl
encrypt = "your_key_from_consul_keygen_command"
encrypt_verify_incoming = true # the only thing that changes
encrypt_verify_outgoing = true
```

10. Restart Consul:

```
systemctl restart consul
```

11. Repeat steps #9 and #10 on all Consul `servers` and `clients`.

Gossip Encryption is now set up!

"But why did we change all of thos incrementally and restart them?"

Steps #3, #4, and #5 are necessary, because all nodes in the Cluster must be made aware of the encryption key.  The `ecnrypt_verify_incoming` parameter enabled would force all of the traffic to immediately have encryption...but before doing so, all of the nodes need to be made aware the key.  Thus, we leave both values set to `false` first.

Steps #6, #7, and #8 turn on `encrypt_verify_outgoing`.  This comes next, because it ensures that outgoing traffic is encrypted.  However, it doesn't require traffic INCOMING to be encrypted, which enables the cluster nodes to continue talking with each other while the rolling update happens.

Finally, Steps #9, #10, and #11 complete the process by enabling `encrypt_verify_incoming`.  Since all nodes are now sending encrypted traffic, its safe to require incoming traffic to be encrypted.

## Part 2 - Secure Consul Agent Communication with TLS Encryption

No real differences here from the learn guide.  In essence we wound up creating the CA certs and the server certs.  We then distributed the CA public to each of the clients.  After that we pointed each of the config files to each of the certs.  Only other note is that we put the certs in their own directory at `/etc/consul.d/certs`.

Note: All of the following, unless stated otherwise, should be done on the SAME Consul server.

1. Create the Certificate Authority certificates used to sign / verify all other certificates:

```
consul tls ca create
```

2. Create the certificates for the Consul server:

```sh
consul tls cert create -server -dc dc1
```

- note: in our live stream, we had scaled down the servers to (1) in order to cut down on manual work.  If you have more than one server, you'll need to repeat this process for each server.

3. Create a new directory to store the certificates:

```sh
mkdir /etc/consul.d/certs
```

4. Move the following certificates to the new directory:

```sh 
# CA public certificate.
mv consul-agent-ca.pem /etc/consul.d/certs/

# Consul server node public certificate for the dc1 datacenter.
mv dc1-server-consul-0.pem /etc/consul.d/certs/

#Consul server node private key for the dc1 datacenter.
mv dc1-server-consul-0-key.pem /etc/consul.d/certs/
```

5. Add the following Consul server's `/etc/consul.d/consul.hcl`:

```hcl
verify_incoming = true

verify_outgoing = true

verify_server_hostname = true

ca_file = "/etc/consul.d/certs/consul-agent-ca.pem"

cert_file = "/etc/consul.d/certs/dc1-server-consul-0.pem"

key_file = "/etc/consul.d/certs/dc1-server-consul-0-key.pem"

auto_encrypt {
  allow_tls = true
}
```

- `verify_incoming` makes sure that any incoming connections are TLS and are signed by the CA's public key (the one that we generated earlier).
- `verify_outgoing` does the same, except makes sure that outgoing traffic uses a certificate signed by the CA's public key.  In this case, those are the certificates specified by `cert_file` and `key_file`.
- `verify_server_hostname` checks that certificates presented match the naming convention of Consul `server.<datacenter>.<domain>` in ADDITION to being signed by the CA.  Again, the CA is just the pair of certificates that we create in step #1 of this section.

6. Copy your `consul-agent-ca.pem` (the server CA's public key) to each Consul client.

7. Create a directory, on each Consul client, for the certificate and move the CA public key to it:

```sh
mkdir /etc/consul.d/certs/
mv consul-agent-ca.pem /etc/consul.d/certs/
```

- This isn't a required directory, but it's a nice place to store your consul related certificates.

8. Add the following to each Consul client's `/etc/consul.d/consul.hcl`:

```hcl
verify_incoming = false

verify_outgoing = true

verify_server_hostname = true

ca_file = "/etc/consul.d/certs/consul-agent-ca.pem"

auto_encrypt = {
  tls = true
}
```

- `auto_encrypt` makes it so that we don't have to manually create certificates for each of the clients.  Instead, with this option, we allow the servers to do the work for us.  They create and distribute the certificates to the clients for us when this option is enabled.

9. Restart the Consul server and all Consul clients:

```sh
# on the servers and clients:
systemctl restart consul
```

## Part 3 - Secure Consul with Access Control Lists (ACLs)

This is the first part of adding ACLs into Consul. As discussed in the stream, these are how we can control access to the Consul API.  We didn't entirely complete it in part 4 and will continue it in part 5.

1. First, stop Consul on ALL of the nodes:

```sh
systemctl stop consul
```

2. On each of the client nodes, stop the service:

```sh
# on the Consul client node with the api service
systemctl stop api

# on the Consul client node with the web service
systemctl stop web
```

3. On the Consul server, add the following block to your `/etc/consul.d/consul.hcl`:

```hcl
acl = {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
}
```

- `enabled` turns on ACL functionality
- `default_policy` sets whether we should ALLOW by default or DENY.  We're going with deny.
- `enable_token_persistence` makes it so that any tokens we set in the API are saved to disk and reloaded on the event that a Consul agent restarts.

4. Bootstrap the initial "master" token for ACLs:

```
consul acl bootstrap
```

- This command creates an unlimited privilege token that to be used for management purposes.  It's shared with all other servers in the quorum (though we only have one in our example).  Once done, the token will need to be used to do anything in Consul, since we turned on "deny" for our default policy.
- Final note - if you lose this token, the only way to recover is to follow the [bootstrap reset procedure](https://learn.hashicorp.com/tutorials/consul/access-control-troubleshoot?utm_source=consul.io&utm_medium=docs#reset-the-acl-system).
- Also, the "token" is the value of the "SecretID" that you'll see as part of the output of this command.

5. To continue interacting with the `consul` API you'll need to set the token:

```
export CONSUL_HTTP_TOKEN=<your_bootstraped_token>
```

6. Generate tokens for **EACH** of the client Consul agents:

```sh
# do this for each Consul client
consul acl token create -node-identity="node_name:data_center"
```
- the format for the `-node-identity` option is `node_name:data_center`.  In this case one of our `node_name`s was "ip-10-255-2-84".  The `data_center` was what we named our data center from way back in the first part of our series.
- again, you'll need to do this for EACH of your Consul client agents.  We had two in the stream, and so we generated two tokens.

7. On **EACH** Consuil client node, add the following to the `/etc/consul.d/consul.hcl` file:

```hcl
acl = {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true

  tokens {
    default = "<your_consul_client_acl_token>"
  }
}
```

- the initial options in the `acl` block work the same way as they do on the server.
- the `token` block is the only new addition and adds one of the tokens we generated in step #5.

8. Return to the Consul server you bootstrapped the "master" ACL token on.  We now need to create tokens for each of the SERVICES.  We created them for the agents, but the serivces (`api`, `web`) also need one as well:

```sh
# create one for the api service
consul acl token create -service-identity="api:dc1"

# create one for the web service
consul acl token create -service-identity="web:dc1"
```

9. Return to each of the Consul client nodes and update the service configuration file to include this token.  If you're following along, that means, first go to the Consul client node with the `api` service and add the following to the file `/etc/consul.d/api.hcl`:

```hcl
service {
  name = "api"
  port = 9090
	# ADD THIS
  token = "<your_token_created_for_api:dc1>"

  check {
    id = "api"
    name = "HTTP API on Port 9090"
    http = "http://localhost:9090/health"
    interval = "30s"
  }
}
```

10. On the Consul client with the `web` service, add the following to the file `/etc/consul.d/web.hcl`:

```hcl
service {
  name = "web"
  port = 9090
  # ADD THIS
  token = "<your_token_created_for_web:dc1>"

  check {
    id = "web"
    name = "HTTP Web on Port 9090"
    http = "http://localhost:9090/health"
    interval = "30s"
  }
}
```

11. On the Consul server, start Consul once again:

```sh
systemctl start consul
```

12. On each of the Consul clients, start Consul AND start the service:

```sh
# on each Consul client
systemctl start consul

# on the api Consul client
systemctl start api

# on the web Consul client
systemctl start web
```

At this point, things should "mostly" be back in order.  HOWEVER.  The `api` and `web` services will not be able to reach each other.  This is because the ACLs we have in place (mostly default ones) are denying this.  We'll fix this in part 5.

