
# Development Environment - Main Terraform Configuration

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "development"
      ManagedBy   = "Terraform"
    }
  }
}

# ============================================================================
# VPC Module
# ============================================================================
module "vpc" {
  source = "../../modules/vpc"

  name               = "ecom-dev"
  cidr_block         = var.vpc_cidr  # REPLACE_ME: "10.20.0.0/16" for dev
  azs                = var.availability_zones
  public_subnets    = var.public_subnet_cidrs
  private_subnets   = var.private_subnet_cidrs
  tags              = merge(var.common_tags, { Name = "ecom-dev-vpc" })
}

# ============================================================================
# IAM Module
# ============================================================================
module "iam" {
  source = "../../modules/iam"

  cluster_name           = var.cluster_name
  github_oidc_url        = var.github_oidc_url
  github_oidc_thumbprint = var.github_oidc_thumbprint
  github_repo            = var.github_repo
  tags                   = merge(var.common_tags, { Name = "ecom-dev-iam" })
}

# ============================================================================
# ECR Module
# ============================================================================
module "ecr" {
  source = "../../modules/ecr"

  name                  = "ecom-app-dev"
  image_tag_mutability  = "MUTABLE"  # Allow tag overwrites in dev
  scan_on_push          = false      # Skip scanning for faster pushes
  tags                  = merge(var.common_tags, { Name = "ecom-app-dev-ecr" })
}

# ============================================================================
# S3 Module
# ============================================================================
module "s3_assets" {
  source = "../../modules/s3"

  bucket_name         = var.assets_bucket_name
  versioning_enabled  = false
  sse_algorithm       = "AES256"
  kms_key_id         = null
  force_destroy       = true  # Easy deletion in dev
  tags                = merge(var.common_tags, { Name = "ecom-assets-dev" })
}

# ============================================================================
# RDS Module
# ============================================================================
module "rds" {
  source = "../../modules/rds"

  name                   = "ecom-dev-db"
  identifier             = "ecom-rds-dev"
  engine                 = "postgres"
  engine_version         = var.rds_engine_version
  instance_class         = "db.t3.micro"               # Smallest for dev
  allocated_storage      = 20                          # Minimal for dev
  storage_type          = "gp2"
  db_name               = "ecomdb"
  username              = var.db_master_username
  password              = var.db_master_password
  subnet_ids            = module.vpc.private_subnets
  security_group_ids    = [aws_security_group.rds.id]
  multi_az              = false                        # Single-AZ for cost
  backup_retention_period = 7
  skip_final_snapshot   = true  # Don't keep snapshots in dev
  tags                  = merge(var.common_tags, { Name = "ecom-rds-dev" })
}

# ============================================================================
# EKS Module
# ============================================================================
module "eks" {
  source = "../../modules/eks"

  cluster_name          = var.cluster_name
  cluster_role_arn      = module.iam.eks_cluster_role_arn
  node_role_arn         = module.iam.eks_node_role_arn
  private_subnet_ids    = module.vpc.private_subnets
  node_desired_capacity = 1                           # Single node for dev
  node_max_capacity     = 2
  node_min_capacity     = 1
  instance_types        = ["t3.small"]                # Small instances for dev
  k8s_version           = var.kubernetes_version
  aws_region            = var.aws_region
  endpoint_public_access = true                       # Allow easy access in dev
  tags                  = merge(var.common_tags, { Name = "ecom-dev-eks" })
}

# ============================================================================
# ALB Module
# ============================================================================
module "alb" {
  source = "../../modules/alb"

  name                 = "ecom-dev"
  public_subnet_ids    = module.vpc.public_subnets
  security_group_ids   = [aws_security_group.alb.id]
  vpc_id               = module.vpc.vpc_id
  target_port          = 80
  target_protocol      = "HTTP"
  health_check_path    = "/health"
  health_check_matcher = "200-399"
  enable_stickiness    = false
  enable_deletion_protection = false
  enable_access_logs   = false
  tags                 = merge(var.common_tags, { Name = "ecom-dev-alb" })
}

# ============================================================================
# CloudWatch Module
# ============================================================================
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  cluster_name       = var.cluster_name
  retention_in_days  = 3  # Minimal retention for cost
  kms_key_id        = null
  tags               = merge(var.common_tags, { Name = "ecom-dev-logs" })
}

# ============================================================================
# Security Groups
# ============================================================================
resource "aws_security_group" "rds" {
  name        = "ecom-dev-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "ecom-dev-rds-sg" })
}

resource "aws_security_group" "eks_nodes" {
  name        = "ecom-dev-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "ecom-dev-eks-nodes-sg" })
}

resource "aws_security_group" "alb" {
  name        = "ecom-dev-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "ecom-dev-alb-sg" })
}
