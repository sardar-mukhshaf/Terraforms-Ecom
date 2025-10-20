# ============================================================================
# S3 Module - Input Variables
# ============================================================================

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
  default     = "ecom-bucket"

  validation {
    condition = (
      length(var.bucket_name) >= 3 && 
      length(var.bucket_name) <= 63 && 
      can(regex("^[a-z0-9.-]*$", var.bucket_name))
    )
    error_message = "Bucket name must be 3-63 characters, lowercase letters, numbers, dots, and hyphens only"
  }
}

variable "versioning_enabled" {
  description = "Enable versioning for object recovery"
  type        = bool
  default     = true

}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm"
  type        = string
  default     = "AES256"
  # REPLACE_ME: Use aws:kms for production with custom KMS keys

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "SSE algorithm must be AES256 or aws:kms"
  }
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (only used if sse_algorithm is aws:kms)"
  type        = string
  default     = null
 
}

variable "force_destroy" {
  description = "Force destroy bucket even if it contains objects"
  type        = bool
  default     = false
  
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
