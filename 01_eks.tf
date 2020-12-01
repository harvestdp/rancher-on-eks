data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_availability_zones" "available" {
}

data "aws_subnet_ids" "cluster_subnet_set" {
  count  = length(var.subnet_name_filters_for_cluster)
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = [var.subnet_name_filters_for_cluster[count.index]]
  }
}

data "aws_subnet_ids" "node_subnet_set" {
  count  = length(var.subnet_name_filters_for_nodes)
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = [var.subnet_name_filters_for_nodes[count.index]]
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "aws_kms_key" "eks" {
  description = "${local.cluster_name}-eks-secrets-key"
}

module "eks" {
  source                       = "github.com/terraform-aws-modules/terraform-aws-eks"
  cluster_name                 = local.cluster_name
  cluster_version              = var.kubernetes_version
  vpc_id                       = data.aws_vpc.vpc.id
  wait_for_cluster_interpreter = var.wait_for_cluster_interpreter

  subnets = flatten([for subnets in data.aws_subnet_ids.cluster_subnet_set : tolist(subnets.ids)])

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  workers_group_defaults = {
    subnets              = flatten([for subnets in data.aws_subnet_ids.node_subnet_set : tolist(subnets.ids)])
    asg_max_size         = var.node_group_max_size
    asg_min_size         = var.node_group_min_size
    asg_desired_capacity = var.node_group_desired_capacity
    instance_type        = var.node_group_instance_type
  }

  node_groups = {
    main = {
      key_name = ""
    }
  }

  tags = {
    Environment = "prod"
  }
}
