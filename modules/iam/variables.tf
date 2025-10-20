# ============================================================================
# IAM Module - Input Variables
# ============================================================================
# This file declares input variables for the IAM module
# ============================================================================

# ============================================================================
# EKS Cluster Naming
# ============================================================================
variable "cluster_name" {
  description = "Name of the EKS cluster (used for role naming)"
  type        = string
    default     = "ecom-prod-cluster"
}

# ============================================================================
# GitHub OIDC Configuration
# ============================================================================
variable "github_oidc_url" {
  description = "GitHub OIDC provider URL"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
  
}

# ============================================================================
# GitHub OIDC Thumbprint
# ============================================================================
variable "github_oidc_thumbprint" {
  description = "Thumbprint of the GitHub OIDC provider certificate"
  type        = string
    default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

# ============================================================================
# GitHub Repository Configuration
# ============================================================================
variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' or 'owner/*' for all repos"
  type        = string
  default     = "myorg/ecommerce-app"
}

# ============================================================================
# Resource Tags
# ============================================================================
variable "tags" {
  description = "Tags to apply to all IAM resources"
  type        = map(string)
  default     = {}
}
