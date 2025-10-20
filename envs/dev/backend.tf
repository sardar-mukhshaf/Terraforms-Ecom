# ============================================================================
# Development Environment - Backend Configuration
# ============================================================================
# Configuration for storing Terraform state in S3 for development environment
# Can share backend with production or have separate backend
# ============================================================================

terraform {
  backend "s3" {
    # REPLACE_ME: S3 bucket name (can be same as prod or different)
    bucket = "REPLACE_ME-tfstate-dev"

    # REPLACE_ME: S3 object key path
    key = "infra/dev/terraform.tfstate"

    # REPLACE_ME: AWS region
    region = "REPLACE_ME-AWS-REGION"

    # REPLACE_ME: DynamoDB table for state locking
    dynamodb_table = "REPLACE_ME-tfstate-lock"

    # Enable encryption
    encrypt = true
  }
}
