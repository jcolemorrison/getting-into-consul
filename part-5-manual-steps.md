# Manual Beginning to End for Part-5

In this process there's far less to do because most of it was just experimentation to understand the policy language for [Consul ACLs](https://www.consul.io/docs/security/acl).  At the end of part 4, we ended with the ACL system in place, but the `api` and `web` services were unable to contact each other.  This was due to the default ACLs not giving enough permissions.

## Enabling Communication between `web` and `api` with ACLs

These instructions assume that you've followed the ACL section of the [Part 4 Manual instructions](part-4-manual-steps.md).

1. Login to the Consul UI using your root token created via the `consul acl bootstrap` command.

2. Click on the **Policies** side navigation opion under the **Access Control Lists** header.

3. Click **Create Policy**.

4. Name the policy `dns-requests`.

5. Under **Rules** input the following:

```hcl
node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "read"
}
```

6. Click **Save**.

7. Click on the **Tokens** side navigation option under the **Access Control Lists** header.

8. Select the "Node Identity" token for the node that your `web` service exists on.

9. Under the **Policies** header, select the `dns-requests` policy we created and click **Save** at the bottom.

At this point, `web` and `api` should be able to interact with each other again.

## Understanding the Policy Language for ACLs

If you're familiar with AWS, the easiest way to think about Tokens and ACLs is like so:

Tokens are like AWS IAM principals.

ACLs are like AWS IAM policies.

Therefore, whenever you issue a token, think of it like having a new AWS IAM user / group / role.  From there you create ACLs and attach them to Tokens which define the permissions of said token.  In our workflow above we had a token for the node on which our `web` service lived.  It was lacking permissions to interact with the node where our `api` service lived.  Therefore we created a new policy and attached it to that token.

Another note, when you update / add / remove policies to a token, you do not have to restart Consul.  It will pick up on those changes automatically.

If you'd like to see a deeper dive into using these with the Nodes, Service, and Consul's KV store, check out the stream where we walk through it!

## Using External CAs

This repo now has a `tls.tf` file that defines the following items:

- A "root CA" private key and public self-signed certificate
- A server private key and "root CA" signed public certificate
- A client-web private key and "root CA" signed public certificate
- A client-api private key and "root CA" signed public certificate

Swapping out an external CA with the built in Consul CA is simply a matter of creating the above.  You can use any service or tool (Let's Encrypt / OpenSSL) to generate those assets.  After you have them you'll pass them in as shown in the [server userdata script](scripts/server.sh) starting at line 58.

