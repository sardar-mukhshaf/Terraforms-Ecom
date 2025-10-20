# ============================================================================
# EKS Module - Input Variables
# ============================================================================
# Variables for configuring the EKS cluster and node groups
# ============================================================================

# ============================================================================
# EKS Cluster Naming
# ============================================================================
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ecom-prod-cluster"
  # REPLACE_ME: Set to 'ecom-prod-cluster' or 'ecom-dev-cluster'
}

# ============================================================================
# IAM Role ARNs
# ============================================================================
variable "cluster_role_arn" {
  description = "ARN of the IAM role for EKS cluster"
  type        = string
  default = "ecom-prod"
}

variable "node_role_arn" {
  description = "ARN of the IAM role for EKS nodes"
  type        = string
  default     = "ecom-prod"
}

# ============================================================================
# Network Configuration
# ============================================================================
variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS cluster and nodes"
  type        = list(string)
  default     = [ "ecom-prod-private-subnet-1", "ecom-prod-private-subnet-2", "ecom-prod-private-subnet-3" ]
}

# ============================================================================
# Kubernetes Version Configuration
# ============================================================================
variable "k8s_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.k8s_version))
    error_message = "Kubernetes version must be in format X.Y (e.g., 1.28)"
  }
}

# ============================================================================
# Node Group Scaling Configuration
# ============================================================================
variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
 

  validation {
    condition     = var.node_desired_capacity > 0
    error_message = "Desired capacity must be at least 1"
  }
}

variable "node_max_capacity" {
  description = "Maximum number of worker nodes for auto-scaling"
  type        = number
  default     = 5
  # REPLACE_ME: Adjust based on expected peak load
}

variable "node_min_capacity" {
  description = "Minimum number of worker nodes for auto-scaling"
  type        = number
  default     = 1
  # REPLACE_ME: Ensure consistency with desired_capacity

  validation {
    condition     = var.node_min_capacity > 0
    error_message = "Min capacity must be at least 1"
  }
}

# ============================================================================
# Node Instance Type Configuration
# ============================================================================
variable "instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

# ============================================================================
# API Endpoint Access Configuration
# ============================================================================
variable "endpoint_public_access" {
  description = "Enable public access to EKS API endpoint"
  type        = bool
  default     = false
}

# ============================================================================
# AWS Region Configuration
# ============================================================================
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  # REPLACE_ME: Must match the region used for VPC and other resources
}

# ============================================================================
# Resource Tags
# ============================================================================
variable "tags" {
  description = "Tags to apply to all EKS resources"
  type        = map(string)
  default     = {}
}

