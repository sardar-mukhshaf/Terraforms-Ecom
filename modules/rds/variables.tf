# ============================================================================
# RDS Module - Input Variables
# ============================================================================
# Configuration variables for the RDS database instance
# ============================================================================

# ============================================================================
# Database Identification
# ============================================================================
variable "name" {
  description = "Name prefix for RDS resources"
  type        = string
  default     = "ecom-rds"
}

variable "identifier" {
  description = "Database instance identifier (unique within region)"
  type        = string
    default     = "ecom-rds-instance"
}

# ============================================================================
# Engine Configuration
# ============================================================================
variable "engine" {
  description = "Database engine type"
  type        = string
  default     = "postgres"


  validation {
    condition     = contains(["postgres", "mysql", "mariadb", "oracle-ee", "oracle-se2", "sqlserver-ex", "sqlserver-web"], var.engine)
    error_message = "Engine must be a valid RDS engine type"
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
    default     = "14.7"
}

variable "instance_class" {
  description = "Database instance class (determines performance/cost)"
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = can(regex("^db\\.", var.instance_class))
    error_message = "Instance class must be a valid RDS instance type (e.g., db.t3.micro)"
  }
}

# ============================================================================
# Storage Configuration
# ============================================================================
variable "allocated_storage" {
  description = "Allocated storage size in GB"
  type        = number
  default     = 20
  # REPLACE_ME: Development: 20-50 GB
  #             Production: 100+ GB (depends on data volume)

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB"
  }
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"

}

variable "iops" {
  description = "IOPS for gp3 or io1/io2 storage"
  type        = number
  default     = 3000

}

variable "kms_key_id" {
  description = "KMS key ID for encryption (optional, uses AWS managed key if not specified)"
  type        = string
  default     = null
  
}

# ============================================================================
# Database Naming and Credentials
# ============================================================================
variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "ecomdb"
  # REPLACE_ME: Set to your database name (no special characters)
}

variable "username" {
  description = "Master database username"
  type        = string
  default     = "admin"
  # REPLACE_ME: Customize username (cannot be 'postgres' for PostgreSQL)
}

variable "password" {
  description = "Master database password"
  type        = string
  sensitive   = true
  # !!!IMPORTANT!!!
  # REPLACE_ME: Use AWS Secrets Manager, Terraform Cloud, or environment variables
  # NEVER commit this to version control
  # Generate strong password: openssl rand -base64 32
}

# ============================================================================
# Network Configuration
# ============================================================================
variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group (must span multiple AZs)"
  type        = list(string)
  # Typically from VPC module: module.vpc.private_subnets
}

variable "security_group_ids" {
  description = "List of security group IDs for database access control"
  type        = list(string)
}

# ============================================================================
# High Availability Configuration
# ============================================================================
variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
  # REPLACE_ME: Production should be true
}

# ============================================================================
# Backup Configuration
# ============================================================================
variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  # REPLACE_ME: Development: 1-7 days
  #             Production: 14-35 days
  #             Compliance requirements may require longer retention

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention must be between 1 and 35 days"
  }
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting database"
  type        = bool
  default     = true
  # REPLACE_ME: Development: true (for faster destruction)
  #             Production: false (always keep final backup)
}

# ============================================================================
# Logging Configuration
# ============================================================================
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
  # REPLACE_ME: For PostgreSQL: ["postgresql"]
  #             Other engines have different log types
  # Helps with troubleshooting and monitoring
}

# ============================================================================
# Resource Tags
# ============================================================================
variable "tags" {
  description = "Tags to apply to all RDS resources"
  type        = map(string)
  default     = {}
}

