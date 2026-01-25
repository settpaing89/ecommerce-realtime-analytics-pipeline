# Lambda Ingestion Module

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "Lambda Execution Role"
  }
}

# IAM Policy for S3 Access
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "${var.project_name}-${var.environment}-lambda-s3-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach AWS Managed Policy for Lambda Basic Execution
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function (placeholder - we'll add code later)
resource "aws_lambda_function" "data_ingestion" {
  filename      = "${path.module}/lambda_placeholder.zip"
  function_name = "${var.project_name}-${var.environment}-ingestion"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name = "Data Ingestion Lambda"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.data_ingestion.function_name}"
  retention_in_days = 7  # Keep logs for 1 week to save costs

  tags = {
    Name = "Lambda Logs"
  }
}

# Outputs
output "function_name" {
  value       = aws_lambda_function.data_ingestion.function_name
  description = "Lambda function name"
}

output "function_arn" {
  value       = aws_lambda_function.data_ingestion.arn
  description = "Lambda function ARN"
}

output "role_arn" {
  value       = aws_iam_role.lambda_role.arn
  description = "Lambda IAM role ARN"
}