# ============================================================================
# ALB Module - Application Load Balancer
# ============================================================================
# This module creates an Application Load Balancer (Layer 7) for:
#   - Distributing HTTP/HTTPS traffic across EKS pods
#   - Health checking pod endpoints
#   - SSL/TLS termination
#   - Path and hostname-based routing
#
# Purpose:
#   - Load balance traffic across EKS services
#   - Provides public access point to applications
#   - Enables auto-scaling based on traffic
#
# Resources Created:
#   - aws_lb: Application Load Balancer
#   - aws_lb_target_group: Pod target group
#   - aws_lb_listener: HTTP/HTTPS listeners
# ============================================================================

# ============================================================================
# Application Load Balancer Resource
# ============================================================================
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.public_subnet_ids

  # Enable deletion protection for production
  enable_deletion_protection = var.enable_deletion_protection

  # Enable access logs for audit and troubleshooting
  access_logs {
    bucket  = var.access_logs_bucket  # REPLACE_ME: S3 bucket for logs (if enabled)
    enabled = var.enable_access_logs
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-alb"
    }
  )
}

# ============================================================================
# Target Group for Kubernetes Services
# ============================================================================
# Pods are registered with this target group for load balancing
resource "aws_lb_target_group" "default" {
  name     = "${var.name}-tg"
  port     = var.target_port
  protocol = var.target_protocol
  vpc_id   = var.vpc_id

  # Health check configuration
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30  # REPLACE_ME: Adjust based on application health check interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher  # REPLACE_ME: Adjust for your app (200-399)
    port                = "traffic-port"
  }

  # Enable stickiness for session persistence (if needed)
  stickiness {
    type            = "lb_cookie"
    enabled         = var.enable_stickiness
    cookie_duration = 86400  # 24 hours
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-tg"
    }
  )
}

# ============================================================================
# HTTP Listener
# ============================================================================
# Listens on port 80 and forwards traffic to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

# ============================================================================
# Optional: HTTPS Listener
# ============================================================================
# Uncomment to enable HTTPS/SSL termination
# REPLACE_ME: Create ACM certificate first or bring existing certificate

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}
#
# # Redirect HTTP to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ============================================================================
# Optional: Path-Based Routing Rules
# ============================================================================
# Uncomment to create additional target groups and routing rules

resource "aws_lb_target_group" "api" {
  name     = "${var.name}-api-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path    = "/health"
    matcher = "200-399"
  }
}
#
resource "aws_lb_listener_rule" "api_routing" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
