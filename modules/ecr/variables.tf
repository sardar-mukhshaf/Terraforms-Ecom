# ============================================================================
# ECR Module - Input Variables
# ============================================================================

variable "name" {
  description = "Name of the ECR repository"
  type        = string
  # REPLACE_ME: e.g., 'ecom-app', 'ecommerce-web-service'
}

variable "image_tag_mutability" {
  description = "Image tag mutability (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
  # REPLACE_ME: IMMUTABLE for production (prevents tag overwrites)

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be MUTABLE or IMMUTABLE"
  }
}

variable "scan_on_push" {
  description = "Scan images for vulnerabilities on push"
  type        = bool
  default     = true
  # REPLACE_ME: true for production (enables security scanning)
}

variable "force_delete" {
  description = "Force delete repository even if it contains images"
  type        = bool
  default     = false
  # REPLACE_ME: true for development (easier cleanup), false for production
}

variable "tags" {
  description = "Tags to apply to the repository"
  type        = map(string)
  default     = {}
}
