# ============================================================================
# Terraform Version & Provider Configuration
# ============================================================================
# This file defines the minimum required versions for Terraform and providers
# used across this infrastructure-as-code repository.
#
# Purpose:
#   - Ensures consistent behavior across different development environments
#   - Prevents breaking changes from incompatible provider versions
#   - Manages provider-specific configurations and authentication
# ============================================================================

terraform {
  # REPLACE_ME: Minimum Terraform version - update if using newer features
  required_version = ">= 1.3.0"

  required_providers {
    # AWS Provider - manages all AWS resources (EKS, RDS, VPC, etc.)
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0" # REPLACE_ME: Update to latest stable version for new features
    }

    # Kubernetes Provider - for managing Kubernetes resources within EKS
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0" # REPLACE_ME: Update version as needed
    }

    # TLS Provider - for certificate and encryption key management
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0" # REPLACE_ME: Update for TLS certificate generation
    }
  }
}

# ============================================================================
# AWS Provider Configuration
# ============================================================================
# Configures the primary AWS provider with the region variable.
# Authentication uses AWS credentials from environment or ~/.aws/credentials
# ============================================================================
provider "aws" {
  region = var.aws_region

  # REPLACE_ME: Optional - add profile for specific AWS credentials
  # profile = "your-profile-name"

  default_tags {
    tags = {
      Project     = "E-Commerce"
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# ============================================================================
# Kubernetes Provider Configuration (Optional)
# ============================================================================
# This is configured dynamically within environment stacks using EKS cluster
# details. Uncomment below if needed at root level.
# ============================================================================
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }

# ============================================================================
# TLS Provider Configuration (Optional)
# ============================================================================
# TLS provider is used for generating self-signed certificates and keys.
# No special configuration is required.
# ============================================================================
