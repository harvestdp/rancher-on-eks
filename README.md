# rancher-on-eks

**This is presented for example only, please take and re-use.**
**This is not a module that is being maintained.**
**There might be some security to revise with this project, it has been used only as a proof-of-concept.**

Terraform-based project to provision an EKS cluster (with a single Managed Node Group) and bootstrap Rancher 2.5.x

# Introduction
With Rancher 2.5.x it is possible to use EKS for cluster hosting Rancher. I couldn't find any examples of how to do this (Nov 2020) so I created this project to get it going.

The order of the installation is:
1. EKS cluster using module [terraform-aws-modules/terraform-aws-eks](https://github.com/terraform-aws-modules/terraform-aws-eks)
1. Creates `cert-manager` namespace
1. Installs `cert-manager` CRDs using a Job running container image `bitnami/kubectl`
1. Installs `cert-manager` Helm chart
1. Installs `ingress-nginx` Helm chart
1. Creates a CNAME record on an existing Route53 Hosted Zone pointing to the ingress load balancer
1. Installs `rancher` Helm chart
1. Configures Rancher `admin` user

# Requirements
The following are required:
* An AWS account
* AWS credentials to create EKS clusters, and manage CNAMEs on a Route53 Hosted Zone, etc
* Terraform v0.13+
* Pre-existing VPC, subnets, internet gateway, routes etc (if you don't have a VPC your can add one using the module [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc), see [here](https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/basic/main.tf) for an example)
* A pre-existing Route53 Hosted Zone 
* A version of `kubectl` on the command line (must be suitable for the EKS version you choose)
* A version of `curl` available on the command line

# Install

:warning: Installing AWS resources does cost money. Please be aware of this.

```
terraform init
terraform plan -out out.terraform
terraform apply out.terraform
```

# Checking cluster

```
export KUBECONFIG=$(find . -type f -name 'kubeconfig_*' | head -n1)
kubectl get pods --all-namespaces
```

:warning: The above is just to get you started. Setting your KUBECONFIG like this is not robust!

# Remove

```
terraform destroy
```

# Variables
The following terraform variables should be set.

Variable name | Type | Default | Description | Example
--- | --- | --- | --- | ---
base_domain | `string` | none | The domain of the existing Route53 Hosted Zone to use | `"test.example.com"`
cert_manager_letsencrypt_email | `string` | none | Let's Encrypt email address for expiration notices | `"you@example.com"`
cert_manager_letsencrypt_environment | `string` | none | Let's Encrypt environment type, must be `"staging"` or `"production"` | `"production"`
cert_manager_version | `string` | none | `cert-manager` Helm chart version to use | `"v1.1.0"`
ingress_nginx_version | `string` | none | `ingress-nginx` Helm chart version to use | `"3.12.0"`
kubernetes_version | `string` | none | The Kubernetes version to choose, must be available for EKS | `"1.18"`
node_group_desired_capacity | `string` | `"1"` | Desired number of nodes (integer as string) | `"1"`
node_group_instance_type | `string` | `"m5.large"` | Instance type for node group | `"m5.large"`
node_group_max_size | `string` | `"1"` | Maximum number of nodes (integer as string) | `"1"`
node_group_min_size | `string` | `"1"` | Minimum number of nodes (integer as string) | `"1"`
rancher_admin_password | `string` | none | Admin password to add to Rancher | something complex!
rancher_version | `string` | none | `cert-manager` Helm chart version to use | `"2.5.2"`
region | `string` | none | AWS region to use | `"ap-southeast-2"`
subnet_name_filters_for_cluster | `list(string)` | none | Used to filter the subnet names to find the subnets for the EKS cluster | `["*.public.*", "*.private.*"]`
subnet_name_filters_for_nodes | `list(string)` | none | Used to filter the subnet names to find the subnets for the nodes | `["*.private.*"]`
vpc_id | `string` | none | VPC ID | `"vpc-123456"`
wait_for_cluster_interpreter | `list(string)` | `["bash", "-c"]` | Shell command for checking/waiting for EKS cluster. See [here](https://github.com/terraform-aws-modules/terraform-aws-eks/#inputs) for more information | `["bash", "-c"]`

# Outputs

Output name | Type | Description | Example
--- | --- | --- | ---
cluster_name | `string` | The EKS cluster name | `rancher-gw5rz60g`
kubeconfig | `string` | The contents of the kubeconfig file | `<sensitive>`
kubeconfig_filename | `string` | The path of the kubeconfig file | `./kubeconfig_rancher-gw5rz60g`
rancher_admin_domain | `string` | Domain name of Rancher instance | `rancher-gw5rz60g.test.example.com`
rancher_admin_url | `string` | URL of Rancher instance | `https://rancher-gw5rz60g.test.example.com`
