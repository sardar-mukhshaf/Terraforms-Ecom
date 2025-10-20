# ============================================================================
# Production Environment - Variables
# ============================================================================
# All values should be provided in terraform.tfvars
# See terraform.tfvars.example for example values
# ============================================================================

# ============================================================================
# AWS Configuration
# ============================================================================
variable "aws_region" {
  description = "AWS region for production infrastructure"
  type        = string
    default     = "us-east-1"
}

variable "availability_zones" {
  description = "List of availability zones (must be 3 for production HA)"
  type        = list(string)
    default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ============================================================================
# VPC Configuration
# ============================================================================
variable "vpc_cidr" {
  description = "CIDR block for production VPC"
  type        = string
  default     = "10.10.0.0/16"
  # REPLACE_ME: Change if conflicts with other VPCs
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB, NAT Gateway)"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
    # REPLACE_ME: Adjust CIDR blocks if needed
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (EKS, RDS)"
  type        = list(string)
  default     = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
  # REPLACE_ME: Adjust CIDR blocks if needed
}

# ============================================================================
# EKS Cluster Configuration
# ============================================================================
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ecom-prod-cluster"
  # REPLACE_ME: Customize if needed
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28"
  # REPLACE_ME: Update to latest stable version
}

variable "eks_desired_nodes" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 3
  # REPLACE_ME: 3+ for production high availability
}

variable "eks_min_nodes" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_max_nodes" {
  description = "Maximum number of EKS worker nodes for auto-scaling"
  type        = number
  default     = 8
  # REPLACE_ME: Adjust based on expected peak load
}

variable "eks_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
  # REPLACE_ME: Use larger instances for production
  # Options: t3.medium, m5.large, m5.xlarge, c5.large, etc.
}

# ============================================================================
# RDS Database Configuration
# ============================================================================
variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.3"
  # REPLACE_ME: Update to latest stable version
}

variable "rds_instance_class" {
  description = "RDS instance class (performance tier)"
  type        = string
  default     = "db.t3.medium"
  # REPLACE_ME: Use larger instances for production workloads
  # Options: db.t3.medium, db.m5.large, db.m5.xlarge, etc.
}

variable "rds_storage_size" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 100
  # REPLACE_ME: Adjust based on data volume
}

variable "db_master_username" {
  description = "Master username for RDS database"
  type        = string
  default     = "admin"
  # REPLACE_ME: Customize username
  sensitive   = true
}

variable "db_master_password" {
  description = "Master password for RDS database"
  type        = string
  # !!!IMPORTANT: NEVER commit this value
  # REPLACE_ME: Use AWS Secrets Manager or Terraform Cloud
  # Generate: openssl rand -base64 32
  sensitive   = true
}

# ============================================================================
# S3 Configuration
# ============================================================================
variable "assets_bucket_name" {
  description = "Name of S3 bucket for e-commerce assets"
  type        = string
  # REPLACE_ME: Must be globally unique, e.g., "ecom-assets-prod-ACCOUNT-ID"
  sensitive   = false
}

variable "s3_kms_key_id" {
  description = "KMS key ID for S3 encryption (optional)"
  type        = string
  default     = null
  # REPLACE_ME: Optional - use custom KMS key for encryption
}

# ============================================================================
# GitHub Actions Configuration
# ============================================================================
variable "github_oidc_url" {
  description = "GitHub OIDC provider URL"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "github_oidc_thumbprint" {
  description = "GitHub OIDC certificate thumbprint"
  type        = string
  # REPLACE_ME: Verify current thumbprint
  # Current: 6938fd4d98bab03faadb97b34396831e3780aea1
}

variable "github_repo" {
  description = "GitHub repository for CI/CD (format: owner/repo)"
  type        = string
  # REPLACE_ME: e.g., "myorg/ecommerce-app" or "myorg/*"
  sensitive   = false
}

# ============================================================================
# CloudWatch Configuration
# ============================================================================
variable "cloudwatch_kms_key_id" {
  description = "KMS key ID for CloudWatch Logs encryption (optional)"
  type        = string
  default     = null
  # REPLACE_ME: Optional - use custom KMS key for log encryption
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "ecommerce"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
