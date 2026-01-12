terraform {
  required_version = ">= 1.6.0"
  backend "s3" {}

  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
}

provider "aws" {
  region = var.region
}

locals {
  ns = "${var.env}-${var.service_name}"
  tags = { Project = var.project, Env = var.env, Service = var.service_name }
}

# Get cluster name + OIDC provider ARN from SSM (written by platform stack)
data "aws_ssm_parameter" "cluster_name" {
  name = "/${var.project}/${var.env}/cluster_name"
}
data "aws_ssm_parameter" "oidc_provider_arn" {
  name = "/${var.project}/${var.env}/oidc_provider_arn"
}

data "aws_eks_cluster" "this" {
  name = data.aws_ssm_parameter.cluster_name.value
}
data "aws_eks_cluster_auth" "this" {
  name = data.aws_ssm_parameter.cluster_name.value
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# Namespace
resource "kubernetes_namespace" "ns" {
  metadata { name = local.ns }
}

# Quota + limit range (baseline governance)
resource "kubernetes_resource_quota" "quota" {
  metadata {
    name      = "quota"
    namespace = local.ns
  }
  spec {
    hard = {
      "requests.cpu"    = "2"
      "requests.memory" = "2Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "4Gi"
      "pods"            = "20"
    }
  }
}

resource "kubernetes_limit_range" "limits" {
  metadata {
    name      = "limits"
    namespace = local.ns
  }
  spec {
    limit {
      type = "Container"
      default = { cpu = "500m", memory = "512Mi" }
      default_request = { cpu = "200m", memory = "256Mi" }
    }
  }
}

# ECR repo per service/env
resource "aws_ecr_repository" "repo" {
  name                 = "${var.service_name}-${var.env}"
  image_tag_mutability = "MUTABLE"
  tags                 = local.tags
}

# Simple secret for demo (created by TF) in Secrets Manager
resource "aws_secretsmanager_secret" "app" {
  name = "${var.env}/${var.service_name}/app"
  tags = local.tags
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret_version" "app_ver" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    DB_USER = "app"
    DB_PASS = random_password.db_password.result
  })
}

output "namespace" { value = local.ns }
output "ecr_repo_url" { value = aws_ecr_repository.repo.repository_url }
output "secrets_manager_name" { value = aws_secretsmanager_secret.app.name }
