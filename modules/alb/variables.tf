# ============================================================================
# ALB Module - Input Variables
# ============================================================================

variable "name" {
  description = "Name prefix for ALB resources"
  type        = string
  # REPLACE_ME: e.g., 'ecom-prod', 'ecommerce-web'
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB deployment"
  type        = list(string)
  # REPLACE_ME: Must span multiple AZs for HA
  # Typically from VPC module: module.vpc.public_subnets
}

variable "security_group_ids" {
  description = "List of security group IDs for ALB"
  type        = list(string)
  # REPLACE_ME: Create security group allowing:
  #   - Inbound: port 80 (HTTP) and 443 (HTTPS) from 0.0.0.0/0
  #   - Outbound: to EKS security group on pod ports
}

variable "vpc_id" {
  description = "VPC ID where ALB will be deployed"
  type        = string
  # Typically from VPC module: module.vpc.vpc_id
}

# ============================================================================
# Target Group Configuration
# ============================================================================
variable "target_port" {
  description = "Port on which targets are running"
  type        = number
  default     = 80
  # REPLACE_ME: Change if application runs on different port (e.g., 8080, 3000)
}

variable "target_protocol" {
  description = "Protocol for communication with targets"
  type        = string
  default     = "HTTP"
  # Options: HTTP, HTTPS, TCP, TLS
  # REPLACE_ME: Use HTTPS for secure pod communication
}

# ============================================================================
# Health Check Configuration
# ============================================================================
variable "health_check_path" {
  description = "Path for ALB health checks"
  type        = string
  default     = "/"
  # REPLACE_ME: Set to actual health check endpoint (e.g., "/health", "/api/status")
}

variable "health_check_matcher" {
  description = "HTTP status codes considered healthy"
  type        = string
  default     = "200-399"
  # REPLACE_ME: Adjust based on application responses (e.g., "200" for exact match)
}

variable "enable_stickiness" {
  description = "Enable session stickiness (sticky sessions)"
  type        = bool
  default     = false
  # REPLACE_ME: true if application requires session persistence
}

# ============================================================================
# ALB Configuration Options
# ============================================================================
variable "enable_deletion_protection" {
  description = "Enable deletion protection for the load balancer"
  type        = bool
  default     = false
  # REPLACE_ME: true for production (prevents accidental deletion)
}

variable "enable_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false
  # REPLACE_ME: true for production (audit and troubleshooting)
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = ""
  # REPLACE_ME: Set if enable_access_logs is true
  # Must allow ALB service to put objects
}

variable "tags" {
  description = "Tags to apply to ALB resources"
  type        = map(string)
  default     = {}
}
