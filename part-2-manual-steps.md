# Manual Beginning to End for Part-2

These are the manual instructions for setting up service discovery with the [Fake Service](https://github.com/nicholasjackson/fake-service) assuming that you've used this repo's Terraform code to create the AWS resources.  The required steps are largely the same between both.  These steps are what one would take if you DID NOT use the `scripts/client-api.sh` and `scripts/client-web.sh` to do the work (though the update to those is pending).

## Beginning to End with API

1. Go to [here to find the Fake Service code](https://github.com/nicholasjackson/fake-service).

    We're using this instead of standing up an acutal application in order to focus on Consul.  This allows us to make a "pretend application" that responds and behaves like a real one.

2. Download it:

```
curl -LO https://github.com/nicholasjackson/fake-service/releases/download/v0.22.7/fake_service_linux_amd64.zip
```

3. Install `unzip` and unzip the bin:

```
sudo apt install unzip
unzip fake_service_linux_amd64.zip
```

4. Move the `fake-service` bin to the the correct location:

```
sudo mv fake-service /usr/local/bin
```

5. Make `fake-service` executable:

```
sudo chmod +x /usr/local/bin/fake-service
```

6. Create a `systemd` file at `/etc/systemd/system/api.service` with the following contents:

```
[Unit]
Description=API
After=syslog.target network.target

[Service]
Environment="MESSAGE=api"
Environment="NAME=api"
ExecStart=/usr/local/bin/fake-service
ExecStop=/bin/sleep 5
Restart=always

[Install]
WantedBy=multi-user.target
```

7. Reload all systemd unit files, so that it's aware of the one we just made:

```
sudo systemctl daemon-reload
```

8. Start the api service with systemd:

```
sudo systemctl start api
```

9. Check that it's working:

```
curl localhost:9090
```

10. Create a new Consul configuration file at `/etc/consul.d/api.hcl`:

```hcl
service {
  name = "api"
  port = 9090
}
```

11. Restart Consul to make it aware fo the new configuration:

```
sudo systemctl restart consul
```

12. Run some checks to see if its working:

```
sudo systemctl status consul
consul catalog services
```

13. Make a new directory at `/etc/systemd/resolved.conf.d`:

- this is following the [instructions here](https://learn.hashicorp.com/tutorials/consul/dns-forwarding#systemd-resolved-setup)

14. Create a new file at `/etc/systemd/resolved.conf.d/consul.conf` with the contents:

```
[Resolve]
DNS=127.0.0.1
Domains=~consul
```

15. Update `iptables` to redirect to the Consul DNS:

```sh
# UDP
sudo iptables --table nat --append OUTPUT --destination localhost --protocol udp --match udp --dport 53 --jump REDIRECT --to-ports 8600

# TCP
sudo iptables --table nat --append OUTPUT --destination localhost --protocol tcp --match tcp --dport 53 --jump REDIRECT --to-ports 8600
```

16. Restart the `systemd-resolver` service:
  - more info on [systemd-resolver](https://wiki.archlinux.org/title/Systemd-resolved)
    - deals in DNS resolution.

```
sudo systemctl restart systemd-resolved
```

17. Run some debug checks to ensure everything is working:

```sh
# that the service resolves to an IP
dig web.service.consul

# that we can interact with it beyond dig
curl web.service.consul:9090
```

Steps 13-16 deal with DNS.  What happens is that Consul has an internal DNS server on port 8600 that allows us to map any *.service.consul to an IP address.  Normally, the DNS goes through a [DNS server in each VPC](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-static-dns-ubuntu-debian/), assuming you're on EC2.  The file that defines this is found at `/etc/resolv.conf`.  However, using `systemd`, we can overwrite rules.  So we create our own file at `/etc/systemd/resolved.conf.d/consul.conf`, with a rule, that awaits any requests meant for `consul` domains in it.  

What this file at `/etc/systemd/resolved.conf.d/consul.conf` says is, that for any inbound requests for the domain `consul` to forward it to `127.0.0.1` instead of to `127.0.0.53` which is the default route that DNS requests go to (which ultimately goes out to the EC2 internal DNS found in each VPC).  Now why?  Well, because Consul has it's own DNS and we want to point any requests meant for Consul to that DNS.

Next question - is this enough?  No, because we're on an older version of `systemd` (< 245).  Consul's DNS is listening on port 8600, and, in this older version of `systemd` we can't specify that a specific port should be used when forwarding requests.  Therefore, we have to intentionally change this with `iptables` to forward any request to port `53` to port `8600`.  This isn't ideal, and isn't required in newer versions of `systemd`.

"But what happens to requests NOT meant for Consul?  So, ones that are meant to go through the normal DNS?"

Well, the very fact that you can still `dig google.com` and everything work means that it's one of the three things:

a) when the request can't resolve, it falls through to the normal DNS server
b) Consul is smart enough to forward it to the normal DNS server
c) Consul IS the DNS server and handles it

## Beginning to End with WEB

1. Go to [here to find the Fake Service code](https://github.com/nicholasjackson/fake-service).

2. Download it:

```
curl -LO https://github.com/nicholasjackson/fake-service/releases/download/v0.22.7/fake_service_linux_amd64.zip
```

3. Install `unzip` and unzip the bin:

```
sudo apt install unzip
unzip fake_service_linux_amd64.zip
```

4. Move the `fake-service` bin to the the correct location:

```
sudo mv fake-service /usr/local/bin
```

5. Make `fake-service` executable:

```
sudo chmod +x /usr/local/bin/fake-service
```

6. Create a `systemd` file at `/etc/systemd/system/web.service` with the following contents:

```systemd
[Unit]
Description=web
After=syslog.target network.target

[Service]
Environment="MESSAGE=I AM WEB"
Environment="NAME=web"
Environment="UPSTREAM_URIS=http://api.service.consul:9090"
ExecStart=/usr/local/bin/fake-service
ExecStop=/bin/sleep 5
Restart=always

[Install]
WantedBy=multi-user.target
```

7. Reload all systemd unit files, so that it's aware of the one we just made:

```
sudo systemctl daemon-reload
```

8. Start the web service with systemd:

```
sudo systemctl start web
```

9. Check that it's working:

```
curl localhost:9090
```

10. Create a new consul configuration file at `/etc/consul.d/web.hcl`:

```hcl
service {
  name = "web"
  port = 9090
}
```

11. Restart consul to make it aware fo the new configuration:

```
sudo systemctl restart consul
```

12. Run some checks to see if its working:

```
sudo systemctl status consul
consul catalog services
```

13. Make a new directory at `/etc/systemd/resolved.conf.d`:

- this is following the [instructions here](https://learn.hashicorp.com/tutorials/consul/dns-forwarding#systemd-resolved-setup)

14. Create a new file at `/etc/systemd/resolved.conf.d/consul.conf` with the contents:

```
[Resolve]
DNS=127.0.0.1
Domains=~consul
```

15. Update `iptables` to redirect to the Consul DNS:

```sh
# UDP
sudo iptables --table nat --append OUTPUT --destination localhost --protocol udp --match udp --dport 53 --jump REDIRECT --to-ports 8600

# TCP
sudo iptables --table nat --append OUTPUT --destination localhost --protocol tcp --match tcp --dport 53 --jump REDIRECT --to-ports 8600
```

16. Restart the `systemd-resolver` service.
  - more info on [systemd-resolver](https://wiki.archlinux.org/title/Systemd-resolved)
    - deals in DNS resolution.

```
sudo systemctl restart systemd-resolved
```

17. Run some debug checks to ensure everything is working:

```sh
# that the service resolves to an IP
dig web.service.consul

# that we can interact with it beyond dig
curl web.service.consul:9090
```