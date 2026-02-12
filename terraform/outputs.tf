# ========================================
# Terraform Outputs Configuration
# E-Commerce Analytics Pipeline
# ========================================

# -----------------
# Account Information
# -----------------

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS Region where resources are deployed"
  value       = data.aws_region.current.name
}

output "deployment_timestamp" {
  description = "Timestamp of the deployment"
  value       = timestamp()
}

# -----------------
# S3 Buckets (Data Lake)
# -----------------

output "s3_buckets" {
  description = "Data lake S3 bucket details"
  value = {
    bronze = {
      name = module.s3_data_lake.bronze_bucket_name
      arn  = module.s3_data_lake.bronze_bucket_arn
      url  = "s3://${module.s3_data_lake.bronze_bucket_name}"
    }
    silver = {
      name = module.s3_data_lake.silver_bucket_name
      arn  = module.s3_data_lake.silver_bucket_arn
      url  = "s3://${module.s3_data_lake.silver_bucket_name}"
    }
    gold = {
      name = module.s3_data_lake.gold_bucket_name
      arn  = module.s3_data_lake.gold_bucket_arn
      url  = "s3://${module.s3_data_lake.gold_bucket_name}"
    }
  }
}

output "bronze_bucket_name" {
  description = "Bronze layer S3 bucket name (for scripts)"
  value       = module.s3_data_lake.bronze_bucket_name
}

output "silver_bucket_name" {
  description = "Silver layer S3 bucket name (for scripts)"
  value       = module.s3_data_lake.silver_bucket_name
}

output "gold_bucket_name" {
  description = "Gold layer S3 bucket name (for scripts)"
  value       = module.s3_data_lake.gold_bucket_name
}

# -----------------
# Lambda Functions
# -----------------

output "lambda_functions" {
  description = "Lambda function details"
  value = {
    ingestion = {
      name = module.lambda_ingestion.function_name
      arn  = module.lambda_ingestion.function_arn
      role = module.lambda_ingestion.role_arn
    }
  }
}

output "lambda_function_name" {
  description = "Lambda function name (for CLI commands)"
  value       = module.lambda_ingestion.function_name
}

# -----------------
# Glue Resources
# -----------------

output "glue_resources" {
  description = "AWS Glue resources"
  value = {
    database = {
      name = aws_glue_catalog_database.ecommerce_db.name
      id   = aws_glue_catalog_database.ecommerce_db.id
    }
    crawler = {
      name = aws_glue_crawler.bronze_crawler.name
      id   = aws_glue_crawler.bronze_crawler.id
    }
  }
}

output "glue_database_name" {
  description = "Glue database name (for Athena queries)"
  value       = aws_glue_catalog_database.ecommerce_db.name
}

output "glue_crawler_name" {
  description = "Glue crawler name (for CLI commands)"
  value       = aws_glue_crawler.bronze_crawler.name
}

# -----------------
# Athena
# -----------------

output "athena_workgroup" {
  description = "Athena workgroup name"
  value       = aws_athena_workgroup.ecommerce_analytics.name
}

output "athena_query_results_location" {
  description = "S3 location for Athena query results"
  value       = "s3://${module.s3_data_lake.gold_bucket_name}/athena-results/"
}

# -----------------
# CloudWatch
# -----------------

output "cloudwatch_dashboard" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.pipeline_dashboard.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.pipeline_dashboard.dashboard_name}"
}

# -----------------
# IAM Roles
# -----------------

output "iam_roles" {
  description = "IAM role ARNs"
  value = {
    lambda_role      = module.lambda_ingestion.role_arn
    glue_crawler_role = aws_iam_role.glue_crawler_role.arn
  }
  sensitive = true
}

# -----------------
# Console URLs
# -----------------

output "aws_console_urls" {
  description = "AWS Console URLs for quick access"
  value = {
    s3_bronze  = "https://s3.console.aws.amazon.com/s3/buckets/${module.s3_data_lake.bronze_bucket_name}"
    s3_silver  = "https://s3.console.aws.amazon.com/s3/buckets/${module.s3_data_lake.silver_bucket_name}"
    s3_gold    = "https://s3.console.aws.amazon.com/s3/buckets/${module.s3_data_lake.gold_bucket_name}"
    lambda     = "https://console.aws.amazon.com/lambda/home?region=${data.aws_region.current.name}#/functions/${module.lambda_ingestion.function_name}"
    glue       = "https://console.aws.amazon.com/glue/home?region=${data.aws_region.current.name}#catalog:tab=databases"
    athena     = "https://console.aws.amazon.com/athena/home?region=${data.aws_region.current.name}"
    cloudwatch = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}"
  }
}

# -----------------
# Next Steps
# -----------------

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value = <<-EOT
  
  ✅ Infrastructure deployed successfully!
  
  📊 Resources Created:
  - S3 Buckets: Bronze, Silver, Gold layers
  - Lambda: ${module.lambda_ingestion.function_name}
  - Glue Database: ${aws_glue_catalog_database.ecommerce_db.name}
  - Glue Crawler: ${aws_glue_crawler.bronze_crawler.name}
  - Athena Workgroup: ${aws_athena_workgroup.ecommerce_analytics.name}
  
  🚀 Next Steps:
  
  1. Generate sample data:
     python src/data_generation/generate_data.py
  
  2. Upload data to S3:
     aws s3 cp data/bronze/ s3://${module.s3_data_lake.bronze_bucket_name}/orders/ --recursive
  
  3. Run Glue Crawler to catalog data:
     aws glue start-crawler --name ${aws_glue_crawler.bronze_crawler.name}
  
  4. Wait for crawler to finish (2-3 minutes):
     aws glue get-crawler --name ${aws_glue_crawler.bronze_crawler.name} --query 'Crawler.State'
  
  5. Query data with Athena:
     Open: https://console.aws.amazon.com/athena/home?region=${data.aws_region.current.name}
     Database: ${aws_glue_catalog_database.ecommerce_db.name}
     SELECT * FROM orders LIMIT 10;
  
  💰 Estimated Cost So Far: ~$0.07
  
  📚 Documentation: See README.md for detailed instructions
  
  EOT
}

# -----------------
# Environment Variables Export
# -----------------

output "env_vars_export" {
  description = "Environment variables for scripts (copy to .env file)"
  value = <<-EOT
  # AWS Resources - Generated by Terraform
  # Add to .env file in project root
  
  AWS_REGION=${data.aws_region.current.name}
  AWS_ACCOUNT_ID=${data.aws_caller_identity.current.account_id}
  
  BRONZE_BUCKET=${module.s3_data_lake.bronze_bucket_name}
  SILVER_BUCKET=${module.s3_data_lake.silver_bucket_name}
  GOLD_BUCKET=${module.s3_data_lake.gold_bucket_name}
  
  LAMBDA_FUNCTION_NAME=${module.lambda_ingestion.function_name}
  
  GLUE_DATABASE=${aws_glue_catalog_database.ecommerce_db.name}
  GLUE_CRAWLER=${aws_glue_crawler.bronze_crawler.name}
  
  ATHENA_WORKGROUP=${aws_athena_workgroup.ecommerce_analytics.name}
  ATHENA_OUTPUT_LOCATION=s3://${module.s3_data_lake.gold_bucket_name}/athena-results/
  
  PROJECT_NAME=${var.project_name}
  ENVIRONMENT=${var.environment}
  EOT
  sensitive = false
}

# -----------------
# Quick Commands
# -----------------

output "quick_commands" {
  description = "Commonly used CLI commands"
  value = <<-EOT
  
  📋 Quick Commands:
  
  # List S3 buckets
  aws s3 ls | grep ${var.project_name}
  
  # Upload file to bronze layer
  aws s3 cp <file> s3://${module.s3_data_lake.bronze_bucket_name}/
  
  # Invoke Lambda function
  aws lambda invoke --function-name ${module.lambda_ingestion.function_name} response.json
  
  # Start Glue Crawler
  aws glue start-crawler --name ${aws_glue_crawler.bronze_crawler.name}
  
  # Check crawler status
  aws glue get-crawler --name ${aws_glue_crawler.bronze_crawler.name}
  
  # List Glue tables
  aws glue get-tables --database-name ${aws_glue_catalog_database.ecommerce_db.name}
  
  # View Lambda logs
  aws logs tail /aws/lambda/${module.lambda_ingestion.function_name} --follow
  
  # Check current AWS costs
  aws ce get-cost-and-usage --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) --granularity MONTHLY --metrics BlendedCost
  
  EOT
}

# -----------------
# Infrastructure Summary
# -----------------

output "infrastructure_summary" {
  description = "Complete infrastructure summary"
  value = {
    project = {
      name        = var.project_name
      environment = var.environment
      region      = data.aws_region.current.name
      account_id  = data.aws_caller_identity.current.account_id
    }
    storage = {
      bronze_bucket = module.s3_data_lake.bronze_bucket_name
      silver_bucket = module.s3_data_lake.silver_bucket_name
      gold_bucket   = module.s3_data_lake.gold_bucket_name
    }
    compute = {
      lambda_function = module.lambda_ingestion.function_name
    }
    catalog = {
      glue_database = aws_glue_catalog_database.ecommerce_db.name
      glue_crawler  = aws_glue_crawler.bronze_crawler.name
    }
    analytics = {
      athena_workgroup = aws_athena_workgroup.ecommerce_analytics.name
    }
    monitoring = {
      cloudwatch_dashboard = aws_cloudwatch_dashboard.pipeline_dashboard.dashboard_name
    }
  }
}

# ============================================
# Step Functions Outputs
# ============================================

output "step_functions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.pipeline.arn
}

output "step_functions_state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.pipeline.name
}

output "step_functions_console_url" {
  description = "AWS Console URL for Step Functions"
  value       = "https://console.aws.amazon.com/states/home?region=${var.aws_region}#/statemachines/view/${aws_sfn_state_machine.pipeline.arn}"
}

output "eventbridge_rule_name" {
  description = "EventBridge rule for daily schedule"
  value       = aws_cloudwatch_event_rule.daily_pipeline.name
}
