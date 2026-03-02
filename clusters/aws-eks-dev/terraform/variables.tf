variable "aws_region" {
  description = "AWS region for the dev EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "triad-aws-eks-dev"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC ID from triad-landing-zones."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by EKS nodes and control plane attachments."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used by ALB-backed ingress."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Managed node group instance types."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired node group size."
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum node group size."
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum node group size."
  type        = number
  default     = 4
}

variable "tags" {
  description = "Additional tags applied to the cluster resources."
  type        = map(string)
  default = {
    Project     = "triad"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

variable "external_dns_hosted_zone_arns" {
  description = "Route 53 hosted zone ARNs external-dns is allowed to manage."
  type        = list(string)
  default     = ["arn:aws:route53:::hostedzone/Z03504361QPV5EQC43B1T"]
}

variable "external_secrets_secret_arns" {
  description = "Secrets Manager secret ARNs external-secrets is allowed to read."
  type        = list(string)
  default = [
    "arn:aws:secretsmanager:us-east-1:971146591534:secret:rds!db-b84b7356-92eb-43fd-bf93-df2842556b62-IxwMhw",
    "arn:aws:secretsmanager:us-east-1:971146591534:secret:triad/dev/observability/*",
  ]
}

variable "alertmanager_sns_topic_arns" {
  description = "SNS topic ARNs Alertmanager is allowed to publish to via IRSA."
  type        = list(string)
  default     = []
}
