# ============================================================================
# Development Environment - Outputs
# ============================================================================

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "s3_bucket_name" {
  description = "S3 assets bucket name"
  value       = module.s3_assets.bucket_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "kubeconfig_instructions" {
  description = "Instructions to configure kubectl"
  value = <<EOT

To configure kubectl for the development cluster:

  aws eks update-kubeconfig \
    --name ${module.eks.cluster_name} \
    --region ${var.aws_region}

Verify connection:

  kubectl cluster-info
  kubectl get nodes

EOT
}
