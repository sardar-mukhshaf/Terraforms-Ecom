# ============================================================================
# RDS Module - Outputs
# ============================================================================
# Exports database connection details for application configuration
# ============================================================================

# ============================================================================
# Database Endpoint Output
# ============================================================================
output "endpoint" {
  description = "RDS database endpoint (hostname:port)"
  value       = aws_db_instance.this.endpoint
  # Used by: Application configuration, connection strings
  # Format: mydb.c9akciq32.us-east-1.rds.amazonaws.com:5432
}

# ============================================================================
# Database Hostname Output
# ============================================================================
output "address" {
  description = "RDS database hostname only"
  value       = aws_db_instance.this.address
  # Used by: Connection strings, DNS references
}

# ============================================================================
# Database Port Output
# ============================================================================
output "port" {
  description = "Database port"
  value       = aws_db_instance.this.port
  # Used by: Connection strings, security group rules
  # Default: 5432 for PostgreSQL, 3306 for MySQL
}

# ============================================================================
# Database Name Output
# ============================================================================
output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.this.db_name
}

# ============================================================================
# Database Master Username Output
# ============================================================================
output "master_username" {
  description = "Master username for database"
  value       = aws_db_instance.this.master_username
  sensitive   = true
}

# ============================================================================
# RDS Database Identifier Output
# ============================================================================
output "db_instance_id" {
  description = "RDS database instance identifier"
  value       = aws_db_instance.this.id
  # Used by: AWS CLI commands, monitoring, snapshots
}

# ============================================================================
# RDS Database ARN Output
# ============================================================================
output "db_instance_arn" {
  description = "ARN of the RDS database instance"
  value       = aws_db_instance.this.arn
  # Used by: IAM policies, event subscriptions, tagging
}

# ============================================================================
# Database Connection String Output
# ============================================================================
output "connection_string" {
  description = "Database connection string for PostgreSQL (other engines have different syntax)"
  value       = "postgresql://${aws_db_instance.this.master_username}:PASSWORD@${aws_db_instance.this.address}:${aws_db_instance.this.port}/${aws_db_instance.this.db_name}"
  sensitive   = true
  # REPLACE_ME: Update format if using different database engine
  # Usage: Replace PASSWORD with actual password
}

# ============================================================================
# Database Engine Output
# ============================================================================
output "engine" {
  description = "Database engine type"
  value       = aws_db_instance.this.engine
}

# ============================================================================
# Database Engine Version Output
# ============================================================================
output "engine_version" {
  description = "Database engine version"
  value       = aws_db_instance.this.engine_version
}

# ============================================================================
# Multi-AZ Status Output
# ============================================================================
output "multi_az" {
  description = "Whether the database is deployed in Multi-AZ"
  value       = aws_db_instance.this.multi_az
}

# ============================================================================
# Storage Type Output
# ============================================================================
output "storage_type" {
  description = "Type of storage used by the database"
  value       = aws_db_instance.this.storage_type
}

# ============================================================================
# DB Subnet Group Output
# ============================================================================
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}
