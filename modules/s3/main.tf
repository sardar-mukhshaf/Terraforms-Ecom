
# S3 Module - Simple Storage Service

resource "aws_s3_bucket" "this" {
  bucket              = var.bucket_name
  force_destroy       = var.force_destroy

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}


# S3 Bucket Versioning

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = false  # REPLACE_ME: Enable for extra safety with MFA requirement
  }
}

# ============================================================================
# S3 Bucket Server-Side Encryption
# ============================================================================
# Encrypts objects at rest using AES-256
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm      = var.sse_algorithm
      kms_master_key_id  = var.kms_key_id  # REPLACE_ME: Optional KMS key for encryption
    }
    bucket_key_enabled = true  # Use bucket key for better performance
  }
}

# ============================================================================
# S3 Public Access Block
# ============================================================================
# Prevents accidental public exposure of bucket contents
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true  # REPLACE_ME: true for maximum security
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
