# ============================================================================
# CloudWatch Module - Logs and Monitoring
# ============================================================================
# This module creates CloudWatch resources for monitoring and logging:
#   - CloudWatch Log Groups for EKS cluster logs
#   - Log retention policies
#   - Optional CloudWatch Alarms
#
# Purpose:
#   - Centralized logging for Kubernetes cluster
#   - Troubleshooting and debugging
#   - Compliance and audit logging
#   - Performance monitoring
#
# Resources Created:
#   - aws_cloudwatch_log_group: Log group for cluster logs
#   - aws_cloudwatch_log_retention_in_days: Log retention policy
# ============================================================================

# ============================================================================
# EKS CloudWatch Log Group
# ============================================================================
# Collects all EKS cluster logs (API, audit, scheduler, etc.)
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}"
  retention_in_days = var.retention_in_days  # REPLACE_ME: Adjust based on requirements

  kms_key_id = var.kms_key_id  # REPLACE_ME: Optional KMS key for log encryption

  tags = merge(
    var.tags,
    {
      Name = "/aws/eks/${var.cluster_name}"
    }
  )
}

# ============================================================================
# Optional: Application Log Group
# ============================================================================
# Separate log group for application logs (if using container insights)
# Uncomment to create

# resource "aws_cloudwatch_log_group" "app" {
#   name              = "/aws/eks/${var.cluster_name}/app"
#   retention_in_days = var.retention_in_days
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "/aws/eks/${var.cluster_name}/app"
#     }
#   )
# }

# ============================================================================
# Optional: CloudWatch Log Group for ALB
# ============================================================================
# Stores Application Load Balancer access logs
# Uncomment to create

# resource "aws_cloudwatch_log_group" "alb" {
#   name              = "/aws/alb/${var.cluster_name}"
#   retention_in_days = var.retention_in_days
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "/aws/alb/${var.cluster_name}"
#     }
#   )
# }

# ============================================================================
# Optional: CloudWatch Alarms
# ============================================================================
# Create alarms for critical metrics (uncomment as needed)

# # CPU Utilization Alarm
# resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
#   alarm_name          = "${var.cluster_name}-high-cpu"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 80  # REPLACE_ME: Adjust based on requirements
#   alarm_description   = "Alarm when CPU exceeds 80%"
# }
#
# # Memory Utilization Alarm
# resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
#   alarm_name          = "${var.cluster_name}-high-memory"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "MemoryUtilization"
#   namespace           = "AWS/ECS"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 80  # REPLACE_ME: Adjust based on requirements
#   alarm_description   = "Alarm when Memory exceeds 80%"
# }

# ============================================================================
# Optional: CloudWatch Log Subscription Filter
# ============================================================================
# Forward logs to Lambda or other destinations (uncomment if needed)

# resource "aws_cloudwatch_log_subscription_filter" "eks_logs" {
#   name            = "eks-logs-filter"
#   log_group_name  = aws_cloudwatch_log_group.eks.name
#   filter_pattern  = "[...]"  # REPLACE_ME: Define filter pattern
#   destination_arn = var.destination_arn
#   # destination_arn could be Lambda ARN, Kinesis stream, etc.
# }
