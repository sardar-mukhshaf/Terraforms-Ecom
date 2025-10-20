# ============================================================================
# Production Environment - Outputs
# ============================================================================
# Exports important infrastructure details for use and documentation
# ============================================================================

# ============================================================================
# EKS Cluster Outputs
# ============================================================================
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority" {
  description = "EKS cluster certificate authority (for kubeconfig)"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_cluster_version" {
  description = "Kubernetes version running on the cluster"
  value       = module.eks.cluster_version
}

# ============================================================================
# ALB Outputs
# ============================================================================
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
  # Use this as CNAME in Route53 or application configuration
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = module.alb.target_group_arn
}

# ============================================================================
# RDS Database Outputs
# ============================================================================
output "rds_endpoint" {
  description = "RDS database endpoint (hostname:port)"
  value       = module.rds.endpoint
  # Use in application database connection strings
}

output "rds_address" {
  description = "RDS database hostname"
  value       = module.rds.address
}

output "rds_port" {
  description = "RDS database port"
  value       = module.rds.port
}

output "rds_database_name" {
  description = "Initial database name"
  value       = module.rds.db_name
}

output "rds_master_username" {
  description = "RDS master username"
  value       = module.rds.master_username
  sensitive   = true
}

# ============================================================================
# ECR Outputs
# ============================================================================
output "ecr_repository_url" {
  description = "ECR repository URL for Docker image pushes"
  value       = module.ecr.repository_url
  # Format: ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/ecom-app
}

output "ecr_registry_id" {
  description = "AWS account ID for ECR repository"
  value       = module.ecr.registry_id
}

# ============================================================================
# S3 Outputs
# ============================================================================
output "s3_bucket_name" {
  description = "Name of the S3 assets bucket"
  value       = module.s3_assets.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 assets bucket"
  value       = module.s3_assets.bucket_arn
}

# ============================================================================
# VPC Outputs
# ============================================================================
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB placement)"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EKS and RDS placement)"
  value       = module.vpc.private_subnets
}

# ============================================================================
# CloudWatch Outputs
# ============================================================================
output "cloudwatch_log_group_name" {
  description = "CloudWatch log group for EKS cluster logs"
  value       = module.cloudwatch.log_group_name
}

# ============================================================================
# IAM Outputs
# ============================================================================
output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions CI/CD"
  value       = module.iam.github_actions_role_arn
  # Configure this in GitHub Actions secrets: AWS_ROLE_TO_ASSUME
}

output "eks_cluster_role_arn" {
  description = "IAM role ARN for EKS cluster"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS worker nodes"
  value       = module.iam.eks_node_role_arn
}

# ============================================================================
# Kubeconfig Configuration Instructions
# ============================================================================
output "kubeconfig_instructions" {
  description = "Instructions to configure kubectl"
  value = <<EOT

To configure kubectl for the production cluster:

  aws eks update-kubeconfig \
    --name ${module.eks.cluster_name} \
    --region ${var.aws_region}

Verify connection:

  kubectl cluster-info
  kubectl get nodes

Configure GitHub Actions:
  1. Create GitHub secret: AWS_ROLE_TO_ASSUME
  2. Value: ${module.iam.github_actions_role_arn}

EOT
}
