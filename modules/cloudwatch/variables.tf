# ============================================================================
# CloudWatch Module - Input Variables
# ============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  # Used to create log group name: /aws/eks/{cluster_name}
}

variable "retention_in_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
  # REPLACE_ME: Development: 3-7 days (cost savings)
  #             Production: 14-30 days (compliance)
  #             Archive: Use S3 for longer retention

  validation {
    condition = (
      var.retention_in_days == 0 ||  # 0 = never expire
      (var.retention_in_days >= 1 && var.retention_in_days <= 3653)
    )
    error_message = "Retention must be 0 (never expire) or 1-3653 days"
  }
}

variable "kms_key_id" {
  description = "KMS key ID for log encryption"
  type        = string
  default     = null
  # REPLACE_ME: Optional - use custom KMS key for log encryption
  # Must have permissions for CloudWatch Logs
}

variable "tags" {
  description = "Tags to apply to CloudWatch resources"
  type        = map(string)
  default     = {}
}
