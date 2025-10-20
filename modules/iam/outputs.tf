# ============================================================================
# IAM Module - Outputs
# ============================================================================
# This file exports IAM role ARNs and other identifiers for use by other modules
# ============================================================================

# ============================================================================
# EKS Cluster Role ARN Output
# ============================================================================
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
  # Used by: EKS module (cluster_role_arn parameter)
}

# ============================================================================
# EKS Cluster Role Name Output
# ============================================================================
output "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.name
  # Used by: Documentation, policy attachments
}

# ============================================================================
# EKS Node Role ARN Output
# ============================================================================
output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.eks_node.arn
  # Used by: EKS module (node_role_arn parameter)
}

# ============================================================================
# EKS Node Role Name Output
# ============================================================================
output "eks_node_role_name" {
  description = "Name of the EKS node IAM role"
  value       = aws_iam_role.eks_node.name
  # Used by: Documentation, policy attachments
}

# ============================================================================
# GitHub Actions Role ARN Output
# ============================================================================
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.arn
  # Used by: GitHub Actions workflows (configure in github-actions-role-arn secret)
}

# ============================================================================
# GitHub Actions Role Name Output
# ============================================================================
output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.name
  # Used by: Documentation, CI/CD configuration
}

# ============================================================================
# GitHub OIDC Provider ARN Output
# ============================================================================
output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider"
  value       = aws_iam_openid_connect_provider.github.arn
  # Used by: Documentation, policy statements
}
