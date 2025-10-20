# ============================================================================
# VPC Module - Outputs
# ============================================================================
# This file exports outputs from the VPC module to be used by other modules.
# These outputs provide essential information about the created network
# infrastructure (VPC ID, subnet IDs, etc.)
# ============================================================================

# ============================================================================
# VPC ID Output
# ============================================================================
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
  # Used by: ALB module (for target group), security group associations
}

# ============================================================================
# VPC CIDR Block Output
# ============================================================================
output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
  # Used by: Security group rules, documentation
}

# ============================================================================
# Public Subnets Output
# ============================================================================
output "public_subnets" {
  description = "List of public subnet IDs"
  value       = [for subnet in aws_subnet.public : subnet.id]
  # Used by: ALB module (for load balancer), NAT Gateway placement
}

# ============================================================================
# Public Subnet CIDR Blocks Output
# ============================================================================
output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = [for subnet in aws_subnet.public : subnet.cidr_block]
  # Used by: Security group rules, documentation
}

# ============================================================================
# Private Subnets Output
# ============================================================================
output "private_subnets" {
  description = "List of private subnet IDs"
  value       = [for subnet in aws_subnet.private : subnet.id]
  # Used by: EKS module (for node group), RDS module (for DB subnet group)
}

# ============================================================================
# Private Subnet CIDR Blocks Output
# ============================================================================
output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = [for subnet in aws_subnet.private : subnet.cidr_block]
  # Used by: Security group rules, documentation
}

# ============================================================================
# Internet Gateway ID Output
# ============================================================================
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
  # Used by: Troubleshooting, VPC peering setup
}

# ============================================================================
# Public Route Table ID Output
# ============================================================================
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
  # Used by: Additional route management, VPC peering
}

# ============================================================================
# Private Route Table ID Output
# ============================================================================
output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
  # Used by: Additional route management, VPC peering
}
