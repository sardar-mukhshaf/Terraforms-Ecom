# ============================================================================
# S3 Module - Outputs
# ============================================================================

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.this.id
  # Used by: S3 operations, CloudFront distribution
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
  # Used by: IAM policies, bucket policies
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_domain_name" {
  description = "DNS name of the bucket"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
  # Used by: CloudFront origin, static website hosting
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}
