# Manual Beginning to End for Part-12

## Prerequisites

The manual instructions are part-12 are the README.md's instructions in the [Part 12 branch](https://github.com/jcolemorrison/getting-into-consul/tree/part-12).

In terms of differences between the [streamed episode](https://www.youtube.com/watch?v=Qw6Re5rRC4E) and following the README are the terraform code changes.  The primary differences are:

- the `hcp.tf` file that includes all relevant resources to using HCP Consul
- addition of security groups to enable communication with HCP consul
- creation of a vpc peering connection between the HCP virtual private network and our consul VPC
- changes to the user data scripts to use the exported config file from HCP
- changes to the `post-apply.sh` script to point to the HCP Consul Cluster endpoint
- addition of variables for HCP Consul settings
- addition of outputs for HCP Consul settings

We did code all of these Terraform changes live on the [episode](https://www.youtube.com/watch?v=Qw6Re5rRC4E), but the manual setup work is largely unchanged from previous episodes.