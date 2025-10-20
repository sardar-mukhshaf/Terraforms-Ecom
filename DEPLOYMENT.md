# 🚀 E-Commerce Infrastructure Deployment Guide

Complete step-by-step guide for deploying production and development environments.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [AWS Setup](#aws-setup)
3. [Production Deployment](#production-deployment)
4. [Development Deployment](#development-deployment)
5. [Post-Deployment Steps](#post-deployment-steps)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)
8. [Cleanup](#cleanup)

---

## Pre-Deployment Checklist

### ✅ Prerequisites

- [ ] AWS Account created (production + development if separate)
- [ ] AWS CLI installed and configured: `aws --version`
- [ ] Terraform installed (>= 1.3.0): `terraform --version`
- [ ] kubectl installed: `kubectl version`
- [ ] Docker installed (for ECR): `docker --version`
- [ ] Git configured: `git config --global user.name "Your Name"`
- [ ] GitHub repository created
- [ ] GitHub OIDC thumbprint obtained

### ✅ AWS Permissions

Ensure IAM user has permissions for:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "eks:*",
        "rds:*",
        "ecr:*",
        "s3:*",
        "iam:*",
        "elasticloadbalancing:*",
        "cloudwatch:*",
        "logs:*",
        "autoscaling:*",
        "dynamodb:*",
        "cloudformation:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### ✅ AWS Account Setup

```bash
# Set AWS account variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-east-1"  # REPLACE_ME

echo "AWS Account: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"

# List available AZs
aws ec2 describe-availability-zones --region $AWS_REGION
```

---

## AWS Setup

### 1. Create S3 Backend Bucket

```bash
# Set variables
BUCKET_NAME="ecom-tfstate-$(date +%s)-$AWS_ACCOUNT_ID"
LOCK_TABLE="ecom-tfstate-lock"

# Create S3 bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_REGION

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "S3 Bucket: $BUCKET_NAME"
```

### 2. Create DynamoDB Lock Table

```bash
# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name $LOCK_TABLE \
  --attribute-definitions \
    AttributeName=LockID,AttributeType=S \
  --key-schema \
    AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput \
    ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region $AWS_REGION

# Wait for table to be active
aws dynamodb wait table-exists \
  --table-name $LOCK_TABLE \
  --region $AWS_REGION

echo "DynamoDB Table: $LOCK_TABLE"
```

### 3. Save Backend Configuration

Create a file to track your backend details:

```bash
cat > backend-config.txt <<EOF
Bucket: $BUCKET_NAME
DynamoDB Table: $LOCK_TABLE
Region: $AWS_REGION
Account ID: $AWS_ACCOUNT_ID
EOF

echo "Backend configuration saved to backend-config.txt"
```

---

## Production Deployment

### Step 1: Prepare Configuration

```bash
# Navigate to production environment
cd envs/prod

# Copy variables template
cp terraform.tfvars.example terraform.tfvars

# List required replacements
grep -n "REPLACE_ME" terraform.tfvars
```

### Step 2: Update terraform.tfvars

Edit `terraform.tfvars` with your production values:

```hcl
# AWS Configuration
aws_region = "us-east-1"
availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

# VPC Configuration
vpc_cidr = "10.10.0.0/16"

# EKS Cluster
cluster_name = "ecom-prod-cluster"
kubernetes_version = "1.28"
eks_desired_nodes = 3
eks_min_nodes = 2
eks_max_nodes = 8

# RDS Database
db_master_username = "admin"
db_master_password = "GenerateStrongPassword123!@#"  # Use openssl rand -base64 32
rds_instance_class = "db.m5.large"
rds_storage_size = 100

# S3 Bucket (must be globally unique)
assets_bucket_name = "ecom-assets-prod-$AWS_ACCOUNT_ID"

# GitHub Actions
github_repo = "your-org/your-repo"
github_oidc_thumbprint = "6938fd4d98bab03faadb97b34396831e3780aea1"

# Tags
common_tags = {
  Project     = "ecommerce"
  Environment = "production"
  ManagedBy   = "Terraform"
  Team        = "platform"
  CostCenter  = "engineering"
}
```

### Step 3: Update backend.tf

Edit `backend.tf` with your S3 bucket details:

```hcl
terraform {
  backend "s3" {
    bucket         = "ecom-tfstate-XXXXXXXXX-123456789012"  # REPLACE_ME
    key            = "infra/prod/terraform.tfstate"
    region         = "us-east-1"                            # REPLACE_ME
    dynamodb_table = "ecom-tfstate-lock"                    # REPLACE_ME
    encrypt        = true
  }
}
```

### Step 4: Initialize Terraform

```bash
# Initialize Terraform (connects to S3 backend)
terraform init

# When prompted, confirm backend configuration

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive ../..
```

### Step 5: Plan Deployment

```bash
# Generate execution plan
terraform plan -out=tfplan

# Review the plan:
# - Number of resources to be created/modified/destroyed
# - Security groups and their rules
# - IAM roles and policies
# - Instance types and sizes
# - Database configuration
# - Network topology

# If satisfied with changes, proceed to apply
```

### Step 6: Apply Infrastructure

```bash
# Deploy infrastructure (takes 15-25 minutes)
# Monitor progress in the terminal

terraform apply tfplan

# Terraform will output important values:
# - EKS Cluster Endpoint
# - RDS Endpoint
# - ALB DNS Name
# - ECR Repository URL
# - S3 Bucket Name
```

### Step 7: Save Outputs

```bash
# Export outputs to JSON for reference
terraform output -json > outputs.json

# Extract specific values
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
ALB_DNS=$(terraform output -raw alb_dns_name)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
ECR_URL=$(terraform output -raw ecr_repository_url)

echo "Cluster: $CLUSTER_NAME"
echo "ALB DNS: $ALB_DNS"
echo "RDS: $RDS_ENDPOINT"
echo "ECR: $ECR_URL"
```

---

## Development Deployment

### Step 1: Navigate to Development Environment

```bash
cd envs/dev

cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Configure Development Variables

Edit `terraform.tfvars`:

```hcl
aws_region = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
cluster_name = "ecom-dev-cluster"
eks_desired_nodes = 1
eks_max_nodes = 2
db_master_password = "dev-password-123"  # Can be simpler for dev
assets_bucket_name = "ecom-assets-dev-$AWS_ACCOUNT_ID"
github_repo = "your-org/your-repo"
```

### Step 3: Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Validate and plan
terraform validate
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Save outputs
terraform output -json > outputs.json
```

---

## Post-Deployment Steps

### Step 1: Configure kubectl

```bash
# Update kubeconfig for production
aws eks update-kubeconfig \
  --name $(cd envs/prod && terraform output -raw eks_cluster_name) \
  --region $(cd envs/prod && terraform output -raw aws_region)

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Step 2: Install Kubernetes Add-ons

```bash
# Install Metrics Server (for HPA and resource monitoring)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify installation
kubectl get deployment metrics-server -n kube-system

# Wait for it to be ready
kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system
```

### Step 3: Create Kubernetes Namespaces

```bash
# Create application namespace
kubectl create namespace production
kubectl create namespace staging

# Create ConfigMaps for database configuration
RDS_ENDPOINT=$(cd envs/prod && terraform output -raw rds_endpoint)
kubectl create configmap db-config \
  --from-literal=DB_HOST=${RDS_ENDPOINT%:*} \
  --from-literal=DB_PORT=5432 \
  --from-literal=DB_NAME=ecomdb \
  -n production

# Verify
kubectl get configmaps -n production
```

### Step 4: Setup GitHub Actions

```bash
# Get GitHub Actions IAM role ARN
GITHUB_ROLE_ARN=$(cd envs/prod && terraform output -raw github_actions_role_arn)

# Create GitHub Actions secret in your repository
# Go to: Settings → Secrets and variables → Actions
# Create new secret: AWS_ROLE_TO_ASSUME
# Value: $GITHUB_ROLE_ARN

echo "Add this to GitHub Actions secret:"
echo "AWS_ROLE_TO_ASSUME=$GITHUB_ROLE_ARN"
```

### Step 5: Setup ECR Login

```bash
# Get authentication token
aws ecr get-login-password --region $(cd envs/prod && terraform output -raw aws_region) | \
  docker login --username AWS --password-stdin \
  $(cd envs/prod && terraform output -raw ecr_registry_id).dkr.ecr.$(cd envs/prod && terraform output -raw aws_region).amazonaws.com

# Verify login was successful
docker images
```

### Step 6: Deploy Initial Application

```bash
# Build and tag image
docker build -t my-ecommerce-app:latest .

# Push to ECR
ECR_URL=$(cd envs/prod && terraform output -raw ecr_repository_url)
docker tag my-ecommerce-app:latest $ECR_URL:latest
docker push $ECR_URL:latest

# Create Kubernetes deployment
cat > deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-app
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ecommerce-app
  template:
    metadata:
      labels:
        app: ecommerce-app
    spec:
      containers:
      - name: app
        image: $ECR_URL:latest
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: db-config
        env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
EOF

# Apply deployment
kubectl apply -f deployment.yaml
```

---

## Verification

### Check Infrastructure

```bash
# Verify EKS cluster
kubectl cluster-info
kubectl get nodes -o wide
kubectl top nodes

# Verify RDS connection
# From an EC2 instance or pod in the cluster:
psql -h $(cd envs/prod && terraform output -raw rds_address) \
  -U admin \
  -d ecomdb \
  -c "SELECT version();"

# Verify ALB
ALB_DNS=$(cd envs/prod && terraform output -raw alb_dns_name)
curl http://$ALB_DNS

# Verify ECR
aws ecr describe-repositories

# Verify S3
aws s3 ls $(cd envs/prod && terraform output -raw s3_bucket_name)
```

### Check Applications

```bash
# List all resources
kubectl get all -n production

# Check deployment status
kubectl get deployment -n production
kubectl describe deployment ecommerce-app -n production

# Check pod logs
kubectl logs -f deployment/ecommerce-app -n production

# Check service endpoints
kubectl get svc -n production
```

### Monitor CloudWatch Logs

```bash
# List log groups
aws logs describe-log-groups

# Get recent logs from EKS cluster
aws logs tail /aws/eks/ecom-prod-cluster --follow

# Query logs
aws logs start-query \
  --log-group-name /aws/eks/ecom-prod-cluster \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | stats count() by @message'
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Error: resource does not exist"

```bash
# Refresh Terraform state
terraform refresh

# Check current state
terraform state list
terraform state show <resource>
```

#### Issue: "Timeout waiting for EKS cluster"

```bash
# Check EKS cluster status
aws eks describe-cluster --name ecom-prod-cluster --query 'cluster.status'

# Check CloudFormation events
aws cloudformation describe-stack-events \
  --stack-name eks-ecom-prod-cluster
```

#### Issue: "RDS database connection refused"

```bash
# Verify security group
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --query 'SecurityGroups[0].IpPermissions'

# Check RDS endpoint
aws rds describe-db-instances \
  --db-instance-identifier ecom-rds-prod \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint]'

# Test connectivity from pod
kubectl run -it --rm test --image=postgres:15 --restart=Never -- \
  psql -h <rds-endpoint> -U admin -d ecomdb -c 'SELECT 1'
```

#### Issue: "ALB not routing traffic"

```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <TG_ARN>

# Check ALB listeners
aws elbv2 describe-listeners \
  --load-balancer-arn <ALB_ARN>

# Check service nodeport
kubectl get svc -n production
```

---

## Cleanup

### Destroy Production Infrastructure

⚠️ **WARNING**: This will delete all resources including databases!

```bash
cd envs/prod

# Create backup of RDS database first!
aws rds create-db-snapshot \
  --db-instance-identifier ecom-rds-prod \
  --db-snapshot-identifier ecom-rds-prod-backup-$(date +%Y%m%d)

# Plan destruction
terraform plan -destroy -out=tfplan-destroy

# Review what will be deleted

# Destroy infrastructure
terraform apply tfplan-destroy

# Delete S3 bucket (if not needed)
aws s3 rm s3://ecom-tfstate-prod --recursive
aws s3api delete-bucket --bucket ecom-tfstate-prod
```

### Destroy Development Infrastructure

```bash
cd envs/dev

# Destroy development environment (safer to delete)
terraform destroy

# Confirm deletion
```

---

## Next Steps

1. **Configure CI/CD**: Set up GitHub Actions workflows for automated deployments
2. **Setup Monitoring**: Configure CloudWatch dashboards and alarms
3. **Enable Auto-Scaling**: Configure Horizontal Pod Autoscaler (HPA) for applications
4. **Backup Strategy**: Set up RDS backup retention and testing procedures
5. **Disaster Recovery**: Document and test recovery procedures
6. **Security Hardening**: Enable WAF on ALB, configure VPC Flow Logs, etc.

---

**For more information, see [README.md](../README.md)**
