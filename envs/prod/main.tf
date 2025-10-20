# ============================================================================
# Production Environment - Main Terraform Configuration
# ============================================================================
# This file orchestrates all production infrastructure resources by calling
# the modules defined in the modules/ directory.
#
# Production Configuration Characteristics:
#   - Multi-AZ deployment for high availability
#   - Larger instance types for performance
#   - 3 EKS nodes (min 2, max 8)
#   - Multi-AZ RDS (automatic failover)
#   - Enhanced monitoring and logging
#   - Private endpoint access with restricted public access
#
# Deployment Steps:
#   1. cd envs/prod
#   2. cp terraform.tfvars.example terraform.tfvars
#   3. Edit terraform.tfvars with production values
#   4. terraform init
#   5. terraform plan
#   6. terraform apply
# ============================================================================

# ============================================================================
# Provider Configuration
# ============================================================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}

# ============================================================================
# VPC Module - Network Infrastructure
# ============================================================================
# Creates VPC with public/private subnets across 3 AZs
module "vpc" {
  source = "../../modules/vpc"

  name               = "ecom-prod"
  cidr_block         = var.vpc_cidr  # REPLACE_ME: "10.10.0.0/16" for prod
  azs                = var.availability_zones
  public_subnets    = var.public_subnet_cidrs
  private_subnets   = var.private_subnet_cidrs
  tags              = merge(var.common_tags, { Name = "ecom-prod-vpc" })
}

# ============================================================================
# IAM Module - Roles and Permissions
# ============================================================================
# Creates IAM roles for EKS cluster, nodes, and GitHub Actions CI/CD
module "iam" {
  source = "../../modules/iam"

  cluster_name            = var.cluster_name
  github_oidc_url         = var.github_oidc_url
  github_oidc_thumbprint  = var.github_oidc_thumbprint
  github_repo             = var.github_repo
  tags                    = merge(var.common_tags, { Name = "ecom-prod-iam" })
}

# ============================================================================
# ECR Module - Docker Image Repository
# ============================================================================
# Creates private Docker registry for container images
module "ecr" {
  source = "../../modules/ecr"

  name                    = "ecom-app"
  image_tag_mutability   = "IMMUTABLE"  # REPLACE_ME: Prevent tag overwrites for production
  scan_on_push           = true         # REPLACE_ME: Enable vulnerability scanning
  tags                   = merge(var.common_tags, { Name = "ecom-app-ecr" })
}

# ============================================================================
# S3 Module - Asset Storage
# ============================================================================
# Creates S3 bucket for storing e-commerce assets (images, uploads, etc.)
module "s3_assets" {
  source = "../../modules/s3"

  bucket_name          = var.assets_bucket_name  # REPLACE_ME: Globally unique bucket name
  versioning_enabled   = true
  sse_algorithm        = "AES256"
  # REPLACE_ME: Use "aws:kms" with custom key ID for encryption at rest
  kms_key_id          = var.s3_kms_key_id
  force_destroy       = false
  tags                = merge(var.common_tags, { Name = "ecom-assets" })
}

# ============================================================================
# RDS Module - PostgreSQL Database
# ============================================================================
# Creates managed PostgreSQL database with automatic backups and failover
module "rds" {
  source = "../../modules/rds"

  name                   = "ecom-db"
  identifier             = "ecom-rds-prod"
  engine                 = "postgres"
  engine_version         = var.rds_engine_version        # REPLACE_ME: "15.3" or latest stable
  instance_class         = var.rds_instance_class         # REPLACE_ME: "db.t3.medium" or larger
  allocated_storage      = var.rds_storage_size           # REPLACE_ME: 100+ GB for production
  storage_type          = "gp3"
  iops                  = 3000                            # REPLACE_ME: Adjust based on performance needs
  db_name               = "ecomdb"
  username              = var.db_master_username          # REPLACE_ME: Customize username
  password              = var.db_master_password          # REPLACE_ME: Use AWS Secrets Manager
  subnet_ids            = module.vpc.private_subnets
  security_group_ids    = [aws_security_group.rds.id]
  multi_az              = true                            # REPLACE_ME: Enable for production HA
  backup_retention_period = 30                            # REPLACE_ME: Adjust retention as needed
  skip_final_snapshot   = false                           # REPLACE_ME: Always keep final snapshot in prod
  enabled_cloudwatch_logs_exports = ["postgresql"]
  tags                  = merge(var.common_tags, { Name = "ecom-rds-prod" })
}

# ============================================================================
# EKS Module - Kubernetes Cluster
# ============================================================================
# Creates managed Kubernetes cluster with auto-scaling node group
module "eks" {
  source = "../../modules/eks"

  cluster_name           = var.cluster_name
  cluster_role_arn       = module.iam.eks_cluster_role_arn
  node_role_arn          = module.iam.eks_node_role_arn
  private_subnet_ids     = module.vpc.private_subnets
  node_desired_capacity  = var.eks_desired_nodes         # REPLACE_ME: 3 for production
  node_max_capacity      = var.eks_max_nodes             # REPLACE_ME: 8 for production
  node_min_capacity      = var.eks_min_nodes             # REPLACE_ME: 2 for high availability
  instance_types         = var.eks_instance_types        # REPLACE_ME: ["t3.medium"] or larger
  k8s_version            = var.kubernetes_version
  aws_region             = var.aws_region
  endpoint_public_access = false                         # REPLACE_ME: true for initial setup, then false
  tags                   = merge(var.common_tags, { Name = "ecom-prod-eks" })
}

# ============================================================================
# ALB Module - Application Load Balancer
# ============================================================================
# Creates load balancer for distributing traffic to Kubernetes services
module "alb" {
  source = "../../modules/alb"

  name                 = "ecom-prod"
  public_subnet_ids    = module.vpc.public_subnets
  security_group_ids   = [aws_security_group.alb.id]
  vpc_id               = module.vpc.vpc_id
  target_port          = 80                              # REPLACE_ME: Change if apps run on different port
  target_protocol      = "HTTP"
  health_check_path    = "/health"                       # REPLACE_ME: Adjust to your app's health endpoint
  health_check_matcher = "200-399"
  enable_stickiness    = false                           # REPLACE_ME: true if apps need sticky sessions
  enable_deletion_protection = true
  enable_access_logs   = false                           # REPLACE_ME: true for production with S3 bucket
  tags                 = merge(var.common_tags, { Name = "ecom-prod-alb" })
}

# ============================================================================
# CloudWatch Module - Logging and Monitoring
# ============================================================================
# Creates CloudWatch log groups for cluster logging
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  cluster_name        = var.cluster_name
  retention_in_days   = 30                               # REPLACE_ME: Adjust based on requirements
  kms_key_id         = var.cloudwatch_kms_key_id
  tags                = merge(var.common_tags, { Name = "ecom-prod-logs" })
}

# ============================================================================
# Security Groups
# ============================================================================
# RDS Security Group - restricts database access
resource "aws_security_group" "rds" {
  name        = "ecom-prod-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  # Allow PostgreSQL access from EKS nodes
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "ecom-prod-rds-sg" })
}

# EKS Nodes Security Group
resource "aws_security_group" "eks_nodes" {
  name        = "ecom-prod-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  # Allow traffic from ALB
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow inter-node communication
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "ecom-prod-eks-nodes-sg" })
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "ecom-prod-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # REPLACE_ME: Restrict to known IPs if possible
  }

  # Allow HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # REPLACE_ME: Restrict to known IPs if possible
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "ecom-prod-alb-sg" })
}
