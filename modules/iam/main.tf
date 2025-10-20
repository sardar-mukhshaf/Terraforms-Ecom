
# IAM Module - Identity and Access Management

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-eks-cluster-role"
    }
  )
}

# ============================================================================
# EKS Cluster Assume Role Policy Document
# ============================================================================
# Allows EKS service to assume this role
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ============================================================================
# EKS Cluster Policy Attachment
# ============================================================================
# Attach AWS managed policy for EKS cluster operations
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ============================================================================
# EKS Node IAM Role
# ============================================================================
# This role is assumed by EC2 worker nodes in the EKS cluster
# Allows nodes to communicate with the control plane and AWS services
resource "aws_iam_role" "eks_node" {
  name               = "${var.cluster_name}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-eks-node-role"
    }
  )
}

# ============================================================================
# EKS Node Assume Role Policy Document
# ============================================================================
# Allows EC2 service to assume this role
data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ============================================================================
# EKS Node Policy Attachments
# ============================================================================
# Attach AWS managed policies for node operations

# Worker Node Policy - basic permissions for EKS nodes
resource "aws_iam_role_policy_attachment" "eks_node_worker_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# CNI Policy - allows nodes to manage VPC networking
resource "aws_iam_role_policy_attachment" "eks_node_cni_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Container Registry Policy - allows pulling images from ECR
resource "aws_iam_role_policy_attachment" "eks_node_ecr_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ============================================================================
# GitHub OIDC Provider Setup
# ============================================================================

resource "aws_iam_openid_connect_provider" "github" {
  url             = var.github_oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_oidc_thumbprint]

  tags = merge(
    var.tags,
    {
      Name = "github-oidc-provider"
    }
  )
}

# ============================================================================
# GitHub Actions IAM Role
# ============================================================================
# This role is assumed by GitHub Actions CI/CD workflows
# Policies attached to this role define what GitHub Actions can do in AWS
resource "aws_iam_role" "github_actions" {
  name               = "${var.cluster_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-github-actions-role"
    }
  )
}

# ============================================================================
# GitHub Actions Assume Role Policy Document
# ============================================================================

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # REPLACE_ME: Adjust for your repository and branch constraints

      values = ["repo:${var.github_repo}:ref:refs/heads/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# ============================================================================
# GitHub Actions Policy
# ============================================================================

resource "aws_iam_policy" "github_actions" {
  name        = "${var.cluster_name}-github-actions-policy"
  description = "Policy for GitHub Actions CI/CD workflows"
  policy      = data.aws_iam_policy_document.github_actions_policy.json

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-github-actions-policy"
    }
  )
}

# ============================================================================
# GitHub Actions Policy Document
# ============================================================================
# REPLACE_ME: Customize permissions based on your CI/CD requirements

data "aws_iam_policy_document" "github_actions_policy" {
  # ========================================================================
  # ECR Permissions - for pushing Docker images
  # ========================================================================
  statement {
    sid       = "ECRPushAccess"
    effect    = "Allow"
    actions   = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = ["*"]
  }

  # ========================================================================
  # EKS Permissions - for updating kubeconfig and cluster access
  # ========================================================================
  statement {
    sid       = "EKSAccess"
    effect    = "Allow"
    actions   = [
      "eks:DescribeCluster",
    ]
    resources = ["*"]
  }

  # ========================================================================
  # S3 Permissions - for artifact storage (if needed)
  # ========================================================================
  statement {
    sid       = "S3ArtifactStorage"
    effect    = "Allow"
    actions   = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    # REPLACE_ME: Restrict to specific S3 bucket ARNs
    resources = ["arn:aws:s3:::*"]
  }
}

# ============================================================================
# GitHub Actions Policy Attachment
# ============================================================================
# Attach the GitHub Actions policy to the GitHub Actions role
resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
