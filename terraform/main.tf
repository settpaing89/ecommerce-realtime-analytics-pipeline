# Main Terraform Configuration - Budget Version ($1.14 total)

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "EcommerceAnalyticsPipeline"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CostCenter  = "Portfolio"
      Budget      = "Under5Dollars"
    }
  }
}

# Data Sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local Variables
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# S3 Data Lake Module (FREE TIER - ~$0.07)
module "s3_data_lake" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# Lambda Ingestion Module (FREE TIER)
module "lambda_ingestion" {
  source = "./modules/lambda"

  project_name       = var.project_name
  environment        = var.environment
  s3_bucket_arn      = module.s3_data_lake.bronze_bucket_arn
  bronze_bucket_name = module.s3_data_lake.bronze_bucket_name
}

# Glue Data Catalog Database (FREE TIER)
resource "aws_glue_catalog_database" "ecommerce_db" {
  name        = "${var.project_name}_${var.environment}"
  description = "E-commerce analytics database"

  tags = {
    Name = "Ecommerce Data Catalog"
  }
}

# Glue Crawler IAM Role
resource "aws_iam_role" "glue_crawler_role" {
  name = "${var.project_name}-${var.environment}-glue-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "Glue Crawler Role"
  }
}

# Attach Glue Service Policy
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# S3 Access Policy for Glue
resource "aws_iam_role_policy" "glue_s3_policy" {
  name = "${var.project_name}-${var.environment}-glue-s3-policy"
  role = aws_iam_role.glue_crawler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_data_lake.bronze_bucket_arn,
          "${module.s3_data_lake.bronze_bucket_arn}/*",
          module.s3_data_lake.silver_bucket_arn,
          "${module.s3_data_lake.silver_bucket_arn}/*",
          module.s3_data_lake.gold_bucket_arn,
          "${module.s3_data_lake.gold_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Glue Crawler for Bronze Layer
resource "aws_glue_crawler" "bronze_crawler" {
  database_name = aws_glue_catalog_database.ecommerce_db.name
  name          = "${var.project_name}-${var.environment}-bronze-crawler"
  role          = aws_iam_role.glue_crawler_role.arn

  s3_target {
    path = "s3://${module.s3_data_lake.bronze_bucket_name}/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  tags = {
    Name = "Bronze Layer Crawler"
  }
}

# Athena Workgroup (for queries - ~$0.50 total)
resource "aws_athena_workgroup" "ecommerce_analytics" {
  name        = "${var.project_name}-${var.environment}-analytics"
  description = "Workgroup for e-commerce analytics queries"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false # Disable to save costs

    result_configuration {
      output_location = "s3://${module.s3_data_lake.gold_bucket_name}/athena-results/"
    }
  }

  tags = {
    Name = "Athena Analytics Workgroup"
  }
}

# ❌ REDSHIFT - COMMENTED OUT FOR NOW (Deploy on Day 14 only)
# We'll uncomment this on Day 14 for 2-hour demo
# Estimated cost: $0.25/hour × 2 = $0.50

# module "redshift_warehouse" {
#   source = "./modules/redshift"
#   
#   project_name       = var.project_name
#   environment        = var.environment
#   database_name      = var.redshift_database_name
#   master_username    = var.redshift_master_username
#   master_password    = var.redshift_master_password
#   node_type          = "dc2.large"
#   number_of_nodes    = 1
# }

# CloudWatch Dashboard (optional - FREE)
resource "aws_cloudwatch_dashboard" "pipeline_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum" }],
            ["AWS/Lambda", "Errors", { stat = "Sum" }],
            ["AWS/Lambda", "Duration", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Lambda Metrics"
        }
      }
    ]
  })
}

# Note: All outputs are now in outputs.tf file

# ============================================
# Step Functions for Pipeline Orchestration
# ============================================

# IAM Role for Step Functions
resource "aws_iam_role" "step_functions" {
  name = "${var.project_name}-${var.environment}-step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Policy for Step Functions
resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.project_name}-${var.environment}-step-functions-policy"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:StartCrawler",
          "glue:GetCrawler"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.project_name}-${var.environment}-pipeline"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    Comment = "E-Commerce Analytics Pipeline"
    StartAt = "RunGlueCrawler"
    States = {
      RunGlueCrawler = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:glue:startCrawler"
        Parameters = {
          Name = "ecommerce-analytics-dev-bronze-crawler"
        }
        Next = "WaitForCrawler"
        Catch = [{
          ErrorEquals = ["Glue.CrawlerRunningException"]
          Next        = "WaitForCrawler"
        }]
        Retry = [{
          ErrorEquals     = ["States.ALL"]
          IntervalSeconds = 2
          MaxAttempts     = 3
          BackoffRate     = 2.0
        }]
      }

      WaitForCrawler = {
        Type    = "Wait"
        Seconds = 60
        Next    = "GetCrawlerStatus"
      }

      GetCrawlerStatus = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:glue:getCrawler"
        Parameters = {
          Name = "ecommerce-analytics-dev-bronze-crawler"
        }
        Next = "CheckCrawlerState"
      }

      CheckCrawlerState = {
        Type = "Choice"
        Choices = [{
          Variable      = "$.Crawler.State"
          StringEquals  = "READY"
          Next          = "PipelineComplete"
        }]
        Default = "WaitForCrawler"
      }

      PipelineComplete = {
        Type = "Succeed"
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_functions" {
  name              = "/aws/vendedlogs/states/${var.project_name}-${var.environment}-pipeline"
  retention_in_days = 7

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# EventBridge Rule for Daily Schedule
resource "aws_cloudwatch_event_rule" "daily_pipeline" {
  name                = "${var.project_name}-${var.environment}-daily-pipeline"
  description         = "Trigger pipeline daily at 2 AM UTC"
  schedule_expression = "cron(0 2 * * ? *)"
  state               = "DISABLED"  # Start disabled, enable after testing

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Role for EventBridge
resource "aws_iam_role" "eventbridge" {
  name = "${var.project_name}-${var.environment}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Policy for EventBridge
resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "${var.project_name}-${var.environment}-eventbridge-policy"
  role = aws_iam_role.eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "states:StartExecution"
      Resource = aws_sfn_state_machine.pipeline.arn
    }]
  })
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "step_function" {
  rule      = aws_cloudwatch_event_rule.daily_pipeline.name
  target_id = "StepFunctionTarget"
  arn       = aws_sfn_state_machine.pipeline.arn
  role_arn  = aws_iam_role.eventbridge.arn
}
