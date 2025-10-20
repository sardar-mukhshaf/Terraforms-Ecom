# ============================================================================
# ALB Module - Outputs
# ============================================================================

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
  # Used by: Application URL configuration, DNS CNAME records
  # Example: ecom-prod-alb-123456789.us-east-1.elb.amazonaws.com
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route53 records)"
  value       = aws_lb.this.zone_id
  # Used by: Route53 alias records
}

output "target_group_arn" {
  description = "ARN of the default target group"
  value       = aws_lb_target_group.default.arn
}

output "target_group_name" {
  description = "Name of the default target group"
  value       = aws_lb_target_group.default.name
}

output "target_group_id" {
  description = "ID of the default target group"
  value       = aws_lb_target_group.default.id
}

output "listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}
