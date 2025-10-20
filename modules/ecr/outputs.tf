# ============================================================================
# ECR Module - Outputs
# ============================================================================

output "repository_url" {
  description = "ECR repository URL for Docker push/pull operations"
  value       = aws_ecr_repository.repo.repository_url
  # Used by: Docker push commands, EKS image references
  # Format: ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/REPO-NAME
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.repo.arn
}

output "registry_id" {
  description = "AWS account ID where repository is created"
  value       = aws_ecr_repository.repo.registry_id
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.repo.name
}
