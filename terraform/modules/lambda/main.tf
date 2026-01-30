# Lambda Ingestion Module - Updated

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "bronze_bucket_name" {
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
}

# S3 Access Policy
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

# Lambda Basic Execution Role
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "data_ingestion" {
  filename      = "${path.root}/../lambda_function.zip"
  function_name = "${var.project_name}-${var.environment}-ingestion"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512  # Increased for pandas/pyarrow

  source_code_hash = filebase64sha256("${path.root}/../lambda_function.zip")
  layers = [
    "arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python311:10"
  ]
  environment {
    variables = {
      BRONZE_BUCKET = var.bronze_bucket_name
      ENVIRONMENT   = var.environment
    }
  }

  tags = {
    Name = "Data Ingestion Lambda"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.data_ingestion.function_name}"
  retention_in_days = 7

  tags = {
    Name = "Lambda Logs"
  }
}

# Outputs
output "function_name" {
  value = aws_lambda_function.data_ingestion.function_name
}

output "function_arn" {
  value = aws_lambda_function.data_ingestion.arn
}

output "role_arn" {
  value = aws_iam_role.lambda_role.arn
}
