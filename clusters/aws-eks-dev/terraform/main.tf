module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access           = true
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = var.node_instance_types
  }

  eks_managed_node_groups = {
    default = {
      desired_size = var.node_desired_size
      min_size     = var.node_min_size
      max_size     = var.node_max_size

      subnet_ids = var.private_subnet_ids
    }
  }

  tags = var.tags
}

module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.tags
}

module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = var.external_dns_hosted_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = var.tags
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-ebs-csi"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

data "aws_caller_identity" "current" {}

locals {
  eks_oidc_provider_hostpath = replace(
    module.eks.oidc_provider_arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/",
    "",
  )
}

data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_provider_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_provider_hostpath}:sub"
      values   = ["system:serviceaccount:kube-system:external-secrets"]
    }
  }
}

data "aws_iam_policy_document" "external_secrets_access" {
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = var.external_secrets_secret_arns
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json
  tags               = var.tags
}

resource "aws_iam_policy" "external_secrets_access" {
  name   = "${var.cluster_name}-external-secrets-access"
  policy = data.aws_iam_policy_document.external_secrets_access.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "external_secrets_access" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets_access.arn
}

data "aws_iam_policy_document" "alertmanager_sns_assume_role" {
  count = length(var.alertmanager_sns_topic_arns) > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_provider_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_provider_hostpath}:sub"
      values   = ["system:serviceaccount:observability:alertmanager"]
    }
  }
}

data "aws_iam_policy_document" "alertmanager_sns_publish" {
  count = length(var.alertmanager_sns_topic_arns) > 0 ? 1 : 0

  statement {
    actions = [
      "sns:Publish",
    ]
    resources = var.alertmanager_sns_topic_arns
  }
}

resource "aws_iam_role" "alertmanager_sns" {
  count = length(var.alertmanager_sns_topic_arns) > 0 ? 1 : 0

  name               = "${var.cluster_name}-alertmanager-sns"
  assume_role_policy = data.aws_iam_policy_document.alertmanager_sns_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_policy" "alertmanager_sns_publish" {
  count = length(var.alertmanager_sns_topic_arns) > 0 ? 1 : 0

  name   = "${var.cluster_name}-alertmanager-sns-publish"
  policy = data.aws_iam_policy_document.alertmanager_sns_publish[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "alertmanager_sns_publish" {
  count = length(var.alertmanager_sns_topic_arns) > 0 ? 1 : 0

  role       = aws_iam_role.alertmanager_sns[0].name
  policy_arn = aws_iam_policy.alertmanager_sns_publish[0].arn
}
