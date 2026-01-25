# S3 Data Lake Module - Bronze, Silver, Gold Architecture
# Fixed version with proper lifecycle configuration

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

data "aws_caller_identity" "current" {}

locals {
  account_id    = data.aws_caller_identity.current.account_id
  bucket_prefix = "${var.project_name}-${var.environment}"
}

# ==========================================
# Bronze Layer - Raw Data
# ==========================================

resource "aws_s3_bucket" "bronze" {
  bucket = "${local.bucket_prefix}-bronze-${local.account_id}"

  tags = {
    Name        = "Bronze Layer - Raw Data"
    Layer       = "bronze"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "bronze" {
  bucket = aws_s3_bucket.bronze.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bronze" {
  bucket = aws_s3_bucket.bronze.id

  rule {
    id     = "transition-to-intelligent-tiering"
    status = "Enabled"

    # FIX: Add filter block (required)
    filter {
      prefix = ""  # Empty prefix means apply to all objects
    }

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# ==========================================
# Silver Layer - Cleaned Data
# ==========================================

resource "aws_s3_bucket" "silver" {
  bucket = "${local.bucket_prefix}-silver-${local.account_id}"

  tags = {
    Name        = "Silver Layer - Cleaned Data"
    Layer       = "silver"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "silver" {
  bucket = aws_s3_bucket.silver.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "silver" {
  bucket = aws_s3_bucket.silver.id

  rule {
    id     = "transition-to-intelligent-tiering"
    status = "Enabled"

    # FIX: Add filter block (required)
    filter {
      prefix = ""  # Empty prefix means apply to all objects
    }

    transition {
      days          = 60
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

# ==========================================
# Gold Layer - Analytics Ready
# ==========================================

resource "aws_s3_bucket" "gold" {
  bucket = "${local.bucket_prefix}-gold-${local.account_id}"

  tags = {
    Name        = "Gold Layer - Analytics Data"
    Layer       = "gold"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "gold" {
  bucket = aws_s3_bucket.gold.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Gold layer: No lifecycle policy (keep data fresh for analytics)

# ==========================================
# Outputs
# ==========================================

output "bronze_bucket_name" {
  value       = aws_s3_bucket.bronze.id
  description = "Bronze layer S3 bucket name"
}

output "bronze_bucket_arn" {
  value       = aws_s3_bucket.bronze.arn
  description = "Bronze layer S3 bucket ARN"
}

output "silver_bucket_name" {
  value       = aws_s3_bucket.silver.id
  description = "Silver layer S3 bucket name"
}

output "silver_bucket_arn" {
  value       = aws_s3_bucket.silver.arn
  description = "Silver layer S3 bucket ARN"
}

output "gold_bucket_name" {
  value       = aws_s3_bucket.gold.id
  description = "Gold layer S3 bucket name"
}

output "gold_bucket_arn" {
  value       = aws_s3_bucket.gold.arn
  description = "Gold layer S3 bucket ARN"
}