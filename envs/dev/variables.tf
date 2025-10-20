
# Development Environment - Variables

variable "aws_region" {
  description = "AWS region for development infrastructure"
  type        = string
default     = "us-east-1"
}

variable "availability_zones" {
  description = "List of availability zones (2 for dev)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  description = "CIDR block for development VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.20.101.0/24", "10.20.102.0/24"]
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ecom-dev-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.3"
}

variable "db_master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_master_password" {
  description = "Master password for RDS"
  type        = string
    default     = "DevPassword123!"  # REPLACE_ME: Use a secure password management solution
  sensitive   = true
}

variable "assets_bucket_name" {
  description = "Name of S3 bucket for assets"
  type        = string
    default     = "ecom-assets-dev-123456789012"  # REPLACE_ME: Ensure globally unique name
}

variable "github_oidc_url" {
  description = "GitHub OIDC provider URL"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "github_oidc_thumbprint" {
  description = "GitHub OIDC certificate thumbprint"
  type        = string
  # REPLACE_ME: Verify current thumbprint
}

variable "github_repo" {
  description = "GitHub repository for CI/CD"
  type        = string
  default     = "myorg/ecommerce-app"
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project     = "ecommerce"
    Environment = "development"
    ManagedBy   = "Terraform"
  }
}
