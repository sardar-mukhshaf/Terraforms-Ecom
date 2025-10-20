# ============================================================================
# RDS Module - Relational Database Service (PostgreSQL)
# ============================================================================
# This module creates a managed PostgreSQL database for the e-commerce platform:
#   - RDS database instance with configurable instance class
#   - DB subnet group for multi-AZ deployment
#   - Automated backups and snapshots
#   - Encryption at rest
#   - Optional read replica support
#
# Purpose:
#   - Provides managed database without maintenance overhead
#   - Supports high availability with multi-AZ configuration
#   - Automated backups for disaster recovery
#
# Resources Created:
#   - aws_db_subnet_group: Subnets for database deployment
#   - aws_db_instance: PostgreSQL database
#   - aws_security_group: Network access control (created separately)
# ============================================================================

# ============================================================================
# DB Subnet Group
# ============================================================================
# Specifies which subnets the database can be deployed to
# Must span multiple AZs for multi-AZ support
resource "aws_db_subnet_group" "this" {
  name            = "${var.name}-db-subnet-group"
  subnet_ids      = var.subnet_ids
  # REPLACE_ME: Ensure these subnets span multiple AZs

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-db-subnet-group"
    }
  )
}

# ============================================================================
# RDS Database Instance
# ============================================================================
# Creates the PostgreSQL database engine
resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = var.engine           # PostgreSQL
  engine_version = var.engine_version   # REPLACE_ME: e.g., "15.3", "14.8"
  instance_class = var.instance_class

  # Database storage configuration
  allocated_storage     = var.allocated_storage  # REPLACE_ME: Size in GB (20+ for dev, 100+ for prod)
  storage_type          = var.storage_type
  iops                  = var.iops  # REPLACE_ME: For gp3, specify IOPS (3000-16000)
  storage_encrypted     = true      # Always encrypt at rest
  kms_key_id            = var.kms_key_id  # REPLACE_ME: Optional custom KMS key

  # Database naming and credentials
  db_name  = var.db_name
  username = var.username
  # REPLACE_ME: Use AWS Secrets Manager or Terraform Cloud for password
  password = var.password

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false  # REPLACE_ME: Keep false for security (use Bastion for access)

  # Backup and maintenance configuration
  backup_retention_period = var.backup_retention_period  # REPLACE_ME: 7-35 days depending on requirements
  backup_window           = "03:00-04:00"                # UTC time - REPLACE_ME: Adjust to off-peak hours
  maintenance_window      = "sun:04:00-sun:05:00"        # UTC - REPLACE_ME: Adjust as needed

  # Multi-AZ configuration for high availability
  multi_az = var.multi_az

  # Skip final snapshot for dev environments
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Enable automatic minor version upgrades
  auto_minor_version_upgrade = true

  # Enable detailed monitoring (requires IAM role)
  # REPLACE_ME: Uncomment and create monitoring role for production
  # monitoring_interval      = 60
  # monitoring_role_arn      = aws_iam_role.rds_monitoring.arn

  # CloudWatch Logs export
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Performance Insights (optional, for performance monitoring)
  # REPLACE_ME: Enable for production for deeper performance analysis
  # performance_insights_enabled          = true
  # performance_insights_retention_period = 7

  tags = merge(
    var.tags,
    {
      Name = var.identifier
    }
  )

  depends_on = [
    aws_db_subnet_group.this
  ]
}

# ============================================================================
# Optional: RDS Read Replica
# ============================================================================
# Uncomment to create a read replica for scaling read operations
# or for disaster recovery in another region

# resource "aws_db_instance" "read_replica" {
#   count              = var.create_read_replica ? 1 : 0
#   identifier         = "${var.identifier}-read-replica"
#   replicate_source_db = aws_db_instance.this.identifier
#   instance_class     = var.replica_instance_class  # Can be different (e.g., smaller)
#   skip_final_snapshot = true
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.identifier}-read-replica"
#     }
#   )
# }

# ============================================================================
# Optional: Database Parameter Group (for custom configurations)
# ============================================================================
# Uncomment to customize database parameters beyond defaults

# resource "aws_db_parameter_group" "this" {
#   name   = "${var.name}-pg"
#   family = "postgres${split(".", var.engine_version)[0]}"
#
#   # REPLACE_ME: Add custom parameters here
#   # Example: max_connections, shared_preload_libraries, etc.
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.name}-pg"
#     }
#   )
# }
