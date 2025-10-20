# ============================================================================
# ECR Module - Elastic Container Registry
# ============================================================================
# This module creates a Docker image repository for storing container images
#
# Purpose:
#   - Private Docker registry for application container images
#   - Integrates with EKS for image pulling
#   - Automatic image scanning for vulnerabilities
#
# Resources Created:
#   - aws_ecr_repository: Docker image repository
#   - aws_ecr_repository_policy: Access control policy
# ============================================================================

# ============================================================================
# ECR Repository Resource
# ============================================================================
resource "aws_ecr_repository" "repo" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability  # REPLACE_ME: MUTABLE or IMMUTABLE
  force_delete         = var.force_delete

  # Image scanning configuration
  image_scanning_configuration {
    scan_on_push = var.scan_on_push  # REPLACE_ME: true for production
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# ============================================================================
# ECR Lifecycle Policy (optional)
# ============================================================================
# Automatically removes old images to manage storage and costs
# Uncomment to enable automatic image cleanup

# resource "aws_ecr_lifecycle_policy" "this" {
#   repository = aws_ecr_repository.repo.name
#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Keep last 10 images, remove others older than 30 days"
#         selection = {
#           tagStatus       = "any"
#           countType       = "imageCountMoreThan"
#           countNumber     = 10
#           countUnit       = "null"
#         }
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
# }

# ============================================================================
# Optional: ECR Repository Policy
# ============================================================================
# Allows other AWS services (like EKS nodes) to pull images
# Uncomment if you need to restrict access

# resource "aws_ecr_repository_policy" "this" {
#   repository = aws_ecr_repository.repo.name
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::ACCOUNT-ID:role/EKSNodeRole"  # REPLACE_ME
#         }
#         Action = [
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage",
#           "ecr:BatchCheckLayerAvailability"
#         ]
#       }
#     ]
#   })
# }
