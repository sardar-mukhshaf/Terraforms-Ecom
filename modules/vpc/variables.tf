
# VPC Module - Input Variables

variable "name" {
  description = "Name prefix for all VPC resources (e.g., 'ecom-prod', 'ecom-dev')"
  type        = string
  default     = "ecom-vpc"
}

# ============================================================================
# VPC CIDR Block Configuration
# ============================================================================
variable "cidr_block" {
  description = "CIDR block for the VPC (must be between /16 and /28)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be a valid IPv4 CIDR block."
  }
}

# ============================================================================
# Availability Zones Configuration
# ============================================================================
variable "azs" {
  description = "List of availability zones for subnet distribution"
  type        = list(string)
    default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ============================================================================
# Public Subnets Configuration
# ============================================================================
# Public subnets are internet-facing and used for ALB and NAT Gateways
variable "public_subnets" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = [ "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24" ]
  validation {
    condition = alltrue([
      for subnet in var.public_subnets : can(cidrhost(subnet, 0))
    ])
    error_message = "All public subnets must be valid CIDR blocks."
  }
}

# ============================================================================
# Private Subnets Configuration
# ============================================================================
# Private subnets host EKS nodes, RDS databases, and internal services
variable "private_subnets" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = [ "10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24" ]

  validation {
    condition = alltrue([
      for subnet in var.private_subnets : can(cidrhost(subnet, 0))
    ])
    error_message = "All private subnets must be valid CIDR blocks."
  }
}

# ============================================================================
# Resource Tags
# ============================================================================
variable "tags" {
  description = "Tags to apply to all VPC resources"
  type        = map(string)
  default     = {
    Team        = "platform"
    Environment = "prod"
    CostCenter  = "engineering"
  }
}
