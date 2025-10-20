# ============================================================================
# Production Environment - Backend Configuration
# ============================================================================
# This file configures Terraform state storage for production environment
# using an S3 backend with DynamoDB locking for safe concurrent access.
#
# Purpose:
#   - Stores Terraform state remotely in S3
#   - Uses DynamoDB for state locking (prevents concurrent modifications)
#   - Enables encryption for state security
#   - Allows team collaboration on infrastructure
#
# Prerequisites:
#   Before applying production infrastructure:
#   1. Create S3 bucket: aws s3api create-bucket --bucket REPLACE_ME-tfstate-prod --region REGION
#   2. Enable versioning: aws s3api put-bucket-versioning --bucket REPLACE_ME-tfstate-prod --versioning-configuration Status=Enabled
#   3. Enable encryption: aws s3api put-bucket-encryption --bucket REPLACE_ME-tfstate-prod ...
#   4. Create DynamoDB table: aws dynamodb create-table --table-name REPLACE_ME-tfstate-lock ...
#
# IMPORTANT: Save this configuration after running terraform init
# ============================================================================

terraform {
  backend "s3" {
    # REPLACE_ME: S3 bucket name (must be globally unique)
    # Format: {organization}-tfstate-prod
    # Example: acme-tfstate-prod
    bucket = "REPLACE_ME-tfstate-prod"

    # REPLACE_ME: S3 object key (path within bucket)
    # Typically: infra/prod/terraform.tfstate
    key = "infra/prod/terraform.tfstate"

    # REPLACE_ME: AWS region where S3 bucket exists
    # Should match provider region
    region = "REPLACE_ME-AWS-REGION"

    # REPLACE_ME: DynamoDB table for state locking
    # Prevents simultaneous modifications by multiple users
    dynamodb_table = "REPLACE_ME-tfstate-lock"

    # Enable encryption at rest for state files
    encrypt = true

    # REPLACE_ME: Optional - AWS profile if using multiple profiles
    # profile = "production"
  }
}
