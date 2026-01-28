

#!/bin/bash
# AWS Resources - Generated from Terraform

export BRONZE_BUCKET=ecommerce-analytics-dev-bronze-396913733976
export SILVER_BUCKET=ecommerce-analytics-dev-silver-396913733976
export GOLD_BUCKET=ecommerce-analytics-dev-gold-396913733976
export LAMBDA_FUNCTION=ecommerce-analytics-dev-ingestion
export GLUE_DATABASE=ecommerce-analytics_dev
export GLUE_CRAWLER=ecommerce-analytics-dev-bronze-crawler
export ATHENA_WORKGROUP=ecommerce-analytics-dev-analytics

# Derived values
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export PROJECT_NAME=ecommerce-analytics
export ENVIRONMENT=dev

echo "✅ AWS resources loaded:"
echo "  Bronze Bucket: $BRONZE_BUCKET"
echo "  Glue Database: $GLUE_DATABASE"
echo "  Glue Crawler: $GLUE_CRAWLER"
export ATHENA_WORKGROUP=ecommerce-analytics-dev-analytics
export GOLD_BUCKET=ecommerce-analytics-dev-gold-396913733976
