# ============================================================================
# Root Level Variables Configuration
# ============================================================================
# This file declares common variables used across the entire Terraform
# infrastructure. These variables can be overridden per environment using
# terraform.tfvars files in the envs/dev and envs/prod directories.
# ============================================================================

# ============================================================================
# AWS Region Configuration
# ============================================================================
variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  # REPLACE_ME: Change to your desired AWS region (e.g., us-east-1, eu-west-1)
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be a valid region code (e.g., us-east-1, eu-west-1)."
  }
}

# ============================================================================
# Common Tags
# ============================================================================
variable "common_tags" {
  description = "Common tags applied to all resources for organization and tracking"
  type        = map(string)
  default = {
    Project   = "ecommerce"
    ManagedBy = "Terraform"
    # REPLACE_ME: Add your organization/team tags
    # Team    = "your-team-name"
    # CostCenter = "your-cost-center"
  }
}

# ============================================================================
# Environment Variable
# ============================================================================
variable "environment" {
  description = "Deployment environment (dev, staging, or prod)"
  type        = string
  # REPLACE_ME: Override per environment - should be set in terraform.tfvars
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be 'dev', 'staging', or 'prod'."
  }
}
