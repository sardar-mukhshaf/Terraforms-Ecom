# ============================================================================
# EKS Module - Outputs
# ============================================================================
# Exports cluster details needed for kubectl access and application deployment
# ============================================================================

# ============================================================================
# EKS Cluster Name Output
# ============================================================================
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
  # Used by: kubectl configuration, deployments, documentation
}

# ============================================================================
# EKS Cluster Endpoint Output
# ============================================================================
output "cluster_endpoint" {
  description = "Endpoint URL of the EKS API server"
  value       = aws_eks_cluster.this.endpoint
  # Used by: kubectl configuration, Kubernetes provider, CI/CD access
}

# ============================================================================
# EKS Cluster Certificate Authority Output
# ============================================================================
output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
  # Used by: kubectl configuration, Kubernetes provider
}

# ============================================================================
# EKS Cluster Version Output
# ============================================================================
output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.this.version
  # Used by: Documentation, version tracking
}

# ============================================================================
# EKS Cluster ARN Output
# ============================================================================
output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
  # Used by: IAM policies, service integrations
}

# ============================================================================
# EKS Node Group ID Output
# ============================================================================
output "node_group_id" {
  description = "ID of the EKS managed node group"
  value       = aws_eks_node_group.managed_nodes.id
  # Used by: Cluster management, monitoring
}

# ============================================================================
# EKS Node Group Status Output
# ============================================================================
output "node_group_status" {
  description = "Status of the EKS managed node group"
  value       = aws_eks_node_group.managed_nodes.status
  # Used by: Health monitoring, troubleshooting
}

# ============================================================================
# AWS Region Output (for kubeconfig generation)
# ============================================================================
output "aws_region" {
  description = "AWS region where the cluster is deployed"
  value       = var.aws_region
  # Used by: kubectl configuration
}

# ============================================================================
# Kubeconfig Data Output
# ============================================================================
# This output provides the complete kubeconfig data structure
# Can be used to programmatically generate kubeconfig files
output "kubeconfig_data" {
  description = "Kubeconfig data for kubectl access (use for reference only)"
  value = base64encode(jsonencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "aws_${aws_eks_cluster.this.name}"
    clusters = [
      {
        name = aws_eks_cluster.this.name
        cluster = {
          certificate-authority-data = aws_eks_cluster.this.certificate_authority[0].data
          server                       = aws_eks_cluster.this.endpoint
        }
      }
    ]
    contexts = [
      {
        name = "aws_${aws_eks_cluster.this.name}"
        context = {
          cluster = aws_eks_cluster.this.name
          user    = "aws_${aws_eks_cluster.this.name}"
        }
      }
    ]
    users = [
      {
        name = "aws_${aws_eks_cluster.this.name}"
        user = {
          exec = {
            apiVersion = "client.authentication.k8s.io/v1beta1"
            command    = "aws"
            args       = ["eks", "get-token", "--cluster-name", aws_eks_cluster.this.name]
          }
        }
      }
    ]
  }))
  sensitive = true
}
