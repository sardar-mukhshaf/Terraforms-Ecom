# ============================================================================
# VPC Module - Virtual Private Cloud Configuration
# ============================================================================
# This module creates the networking infrastructure for the e-commerce platform:
#   - VPC with customizable CIDR block
#   - Public subnets (for ALB and NAT Gateways)
#   - Private subnets (for EKS and RDS)
#   - Internet Gateway for public subnet routing
#   - Route tables and associations for traffic management
#   - Security groups (optional - can be created here or separately)
#
# Purpose:
#   - Provides isolated network environment within AWS
#   - Enables multi-AZ deployment for high availability
#   - Separates public-facing and private resources
#
# Resources Created:
#   - aws_vpc: Main VPC network
#   - aws_internet_gateway: Public internet access
#   - aws_subnet: Public and private subnets across multiple AZs
#   - aws_route_table: Traffic routing rules
#   - aws_route_table_association: Subnet-to-route-table mapping
#   - aws_eip: Elastic IPs for NAT Gateways (optional)
#   - aws_nat_gateway: For private subnet internet access (optional)
# ============================================================================

# ============================================================================
# VPC Resource
# ============================================================================
# Creates the main VPC that will contain all networking resources
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}

# ============================================================================
# Internet Gateway Resource
# ============================================================================
# Provides a route for public subnets to communicate with the internet
# Required for ALB and public-facing resources
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

# ============================================================================
# Public Subnets
# ============================================================================
# Public subnets are used for:
#   - Application Load Balancer (ALB)
#   - NAT Gateways (if using private subnets)
# These subnets automatically assign public IPs and have internet access
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnets : idx => cidr }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  # REPLACE_ME: Adjust availability zones based on your region (e.g., us-east-1a, us-east-1b)
  availability_zone = element(var.azs, tonumber(each.key))

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-subnet-${each.key + 1}"
      Type = "Public"
    }
  )
}

# ============================================================================
# Private Subnets
# ============================================================================
# Private subnets are used for:
#   - EKS worker nodes
#   - RDS database instances
#   - Internal application components
# These subnets do NOT have direct internet access but can use NAT Gateway
resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnets : idx => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  # REPLACE_ME: Adjust availability zones based on your region
  availability_zone = element(var.azs, tonumber(each.key))

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-subnet-${each.key + 1}"
      Type = "Private"
    }
  )
}

# ============================================================================
# Public Route Table
# ============================================================================
# Routes traffic for public subnets to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-rt"
    }
  )
}

# ============================================================================
# Default Route for Public Traffic
# ============================================================================
# All traffic destined for 0.0.0.0/0 (any external IP) is routed to IGW
resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# ============================================================================
# Public Route Table Associations
# ============================================================================
# Associates each public subnet with the public route table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# Private Route Table (Optional)
# ============================================================================
# Routes traffic for private subnets (can route through NAT Gateway if needed)
# For production, consider adding NAT Gateway for private subnet internet access
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-rt"
    }
  )
}

# ============================================================================
# Private Route Table Associations
# ============================================================================
# Associates each private subnet with the private route table
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# ============================================================================
# Optional: NAT Gateway Setup for Private Subnet Internet Access
# ============================================================================
# Uncomment this section if private subnets need outbound internet access
# (Required for Amazon ECR, public container registries, etc.)
#
# resource "aws_eip" "nat" {
#   count  = var.enable_nat_gateway ? length(var.public_subnets) : 0
#   domain = "vpc"
#   tags   = merge(var.tags, { Name = "${var.name}-eip-nat-${count.index + 1}" })
# }
#
# resource "aws_nat_gateway" "this" {
#   count         = var.enable_nat_gateway ? length(var.public_subnets) : 0
#   allocation_id = aws_eip.nat[count.index].id
#   subnet_id     = aws_subnet.public[tostring(count.index)].id
#   tags          = merge(var.tags, { Name = "${var.name}-nat-${count.index + 1}" })
# }
#
# resource "aws_route" "private_nat_route" {
#   count              = var.enable_nat_gateway ? 1 : 0
#   route_table_id     = aws_route_table.private.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id     = aws_nat_gateway.this[0].id
# }
