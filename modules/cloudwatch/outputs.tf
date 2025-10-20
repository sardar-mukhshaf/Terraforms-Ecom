# ============================================================================
# CloudWatch Module - Outputs
# ============================================================================

output "log_group_name" {
  description = "Name of the EKS CloudWatch log group"
  value       = aws_cloudwatch_log_group.eks.name
}

output "log_group_arn" {
  description = "ARN of the EKS CloudWatch log group"
  value       = aws_cloudwatch_log_group.eks.arn
}

output "log_group_retention_in_days" {
  description = "Log retention period in days"
  value       = aws_cloudwatch_log_group.eks.retention_in_days
}
