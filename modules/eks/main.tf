# ============================================================================
# EKS Module - Elastic Kubernetes Service Configuration
# ============================================================================
# This module creates and manages an AWS EKS cluster for container orchestration:
#   - EKS Control Plane (managed by AWS)
#   - Managed Node Groups (EC2 instances running Kubernetes nodes)
#   - OIDC provider for pod-level IAM roles
#   - Auto-scaling configuration for nodes
#
# Purpose:
#   - Provides managed Kubernetes service on AWS
#   - Simplifies cluster management and security patching
#   - Enables pod-to-AWS-service authentication via IAM roles
#
# Resources Created:
#   - aws_eks_cluster: Kubernetes control plane
#   - aws_eks_node_group: Managed worker nodes
#   - aws_eks_addon: Add-ons like VPC CNI, CoreDNS, kube-proxy
#   - null_resource: Local-exec for kubeconfig updates (optional)
# ============================================================================

# ============================================================================
# EKS Cluster Resource
# ============================================================================
# Creates the managed Kubernetes control plane
resource "aws_eks_cluster" "this" {
  name            = var.cluster_name
  role_arn        = var.cluster_role_arn
  version         = var.k8s_version
  # REPLACE_ME: Update version when new Kubernetes versions are released

  # VPC Configuration for cluster networking
  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    # REPLACE_ME: Set to false for production (restrict public access)
    endpoint_public_access  = var.endpoint_public_access
    # REPLACE_ME: If endpoint_public_access is true, restrict to known IPs
    # public_access_cidrs   = ["YOUR_IP/32"]
  }

  # Enable control plane logging (optional but recommended)
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )

  # Ensure IAM role is created before cluster
  depends_on = [
    var.cluster_role_arn
  ]
}

# ============================================================================
# EKS Managed Node Group
# ============================================================================
# Creates auto-scaling EC2 instances running Kubernetes nodes
resource "aws_eks_node_group" "managed_nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-managed-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  version         = var.k8s_version

  # Scaling configuration
  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = var.node_max_capacity
    min_size     = var.node_min_capacity
  }

  # Instance types for nodes
  # REPLACE_ME: Adjust based on workload requirements
  # t3 instances: burstable, cost-effective for variable workloads
  # m5 instances: general purpose, consistent performance
  # c5 instances: compute optimized for CPU-intensive tasks
  instance_types = var.instance_types

  # Disk size for node volumes
  # REPLACE_ME: Increase for applications with large storage needs
  disk_size = 50

  # Remote access configuration (for SSH access to nodes)
  # REPLACE_ME: Configure SSH key and security groups for node access
  # remote_access {
  #   ec2_ssh_key               = "your-key-pair-name"
  #   source_security_group_ids = [var.bastion_security_group_id]
  # }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-managed-node-group"
    }
  )

  # Update strategy (how nodes are updated)
  update_config {
    max_unavailable = 1  # REPLACE_ME: Adjust based on cluster size and requirements
  }

  # Ensure cluster and IAM role exist before creating nodes
  depends_on = [
    aws_eks_cluster.this,
    var.node_role_arn
  ]
}

# ============================================================================
# EKS Cluster Auto-scaling Configuration
# ============================================================================
# Update the Auto Scaling Group tags for Kubernetes Cluster Autoscaler
# This enables the Cluster Autoscaler addon to automatically scale nodes
# based on pod resource requests

resource "aws_autoscaling_group_tag" "cluster_autoscaler" {
  for_each = toset(
    data.aws_autoscaling_groups.node_group.names
  )

  autoscaling_group_name = each.value

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = false
  }
}

# Data source to get the Auto Scaling Group names associated with the node group
data "aws_autoscaling_groups" "node_group" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = [aws_eks_node_group.managed_nodes.node_group_name]
  }
}

# ============================================================================
# Optional: EKS Add-ons Configuration
# ============================================================================
# EKS add-ons are managed plugins that extend cluster functionality
# Uncomment these to install core add-ons

# # VPC CNI - Container Network Interface for pod networking
# resource "aws_eks_addon" "vpc_cni" {
#   cluster_name             = aws_eks_cluster.this.name
#   addon_name               = "vpc-cni"
#   addon_version            = var.vpc_cni_version # REPLACE_ME: Specify version
#   resolve_conflicts_on_update = "OVERWRITE"
# }
#
# # CoreDNS - DNS resolution for Kubernetes services
# resource "aws_eks_addon" "coredns" {
#   cluster_name             = aws_eks_cluster.this.name
#   addon_name               = "coredns"
#   addon_version            = var.coredns_version # REPLACE_ME: Specify version
#   resolve_conflicts_on_update = "OVERWRITE"
# }
#
# # kube-proxy - Network proxy for Kubernetes services
# resource "aws_eks_addon" "kube_proxy" {
#   cluster_name             = aws_eks_cluster.this.name
#   addon_name               = "kube-proxy"
#   addon_version            = var.kube_proxy_version # REPLACE_ME: Specify version
#   resolve_conflicts_on_update = "OVERWRITE"
# }

# ============================================================================
# Optional: Update kubeconfig for Local kubectl Access
# ============================================================================
# Uncomment to automatically configure kubectl to access the cluster
# This runs locally after the EKS cluster is created

# resource "null_resource" "update_kubeconfig" {
#   provisioner "local-exec" {
#     command = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${var.aws_region}"
#   }
#
#   triggers = {
#     cluster_id = aws_eks_cluster.this.id
#   }
# }
