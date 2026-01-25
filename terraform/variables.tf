# ========================================
# Terraform Variables Configuration
# E-Commerce Analytics Pipeline
# ========================================

# -----------------
# AWS Configuration
# -----------------

variable "aws_region" {
  description = "AWS region for deploying resources"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region name (e.g., us-east-1)."
  }
}

# -----------------
# Project Settings
# -----------------

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "ecommerce-analytics"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Project owner/maintainer email or name"
  type        = string
  default     = "data-engineering-team"
}

# -----------------
# S3 Configuration
# -----------------

variable "enable_s3_versioning" {
  description = "Enable versioning on S3 buckets"
  type        = bool
  default     = true
}

variable "s3_lifecycle_glacier_days" {
  description = "Number of days before transitioning to Glacier storage"
  type        = number
  default     = 90
}

variable "s3_lifecycle_expiration_days" {
  description = "Number of days before deleting old data"
  type        = number
  default     = 365
}

# -----------------
# Lambda Configuration
# -----------------

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.11"
  
  validation {
    condition     = contains(["python3.9", "python3.10", "python3.11", "python3.12"], var.lambda_runtime)
    error_message = "Lambda runtime must be a supported Python version."
  }
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
  
  validation {
    condition     = var.lambda_timeout >= 3 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 3 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
  
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}

# -----------------
# Glue Configuration
# -----------------

variable "glue_crawler_schedule" {
  description = "Cron expression for Glue Crawler schedule (leave empty for manual runs)"
  type        = string
  default     = ""
  # Example: "cron(0 2 * * ? *)" runs daily at 2 AM UTC
}

# -----------------
# CloudWatch Configuration
# -----------------

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

# -----------------
# Redshift Configuration (for Day 14)
# -----------------

variable "redshift_database_name" {
  description = "Redshift database name"
  type        = string
  default     = "ecommerce_dw"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.redshift_database_name))
    error_message = "Database name must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "redshift_master_username" {
  description = "Redshift master username"
  type        = string
  default     = "admin"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.redshift_master_username))
    error_message = "Username must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "redshift_master_password" {
  description = "Redshift master password (set via environment variable TF_VAR_redshift_master_password)"
  type        = string
  sensitive   = true
  default     = ""
  
  validation {
    condition     = var.redshift_master_password == "" || (length(var.redshift_master_password) >= 8 && can(regex("[A-Z]", var.redshift_master_password)) && can(regex("[a-z]", var.redshift_master_password)) && can(regex("[0-9]", var.redshift_master_password)))
    error_message = "Password must be at least 8 characters with uppercase, lowercase, and numbers."
  }
}

variable "redshift_node_type" {
  description = "Redshift node type (dc2.large for free tier eligible)"
  type        = string
  default     = "dc2.large"
}

variable "redshift_number_of_nodes" {
  description = "Number of Redshift nodes (1 for single-node cluster)"
  type        = number
  default     = 1
  
  validation {
    condition     = var.redshift_number_of_nodes >= 1 && var.redshift_number_of_nodes <= 100
    error_message = "Number of nodes must be between 1 and 100."
  }
}

variable "enable_redshift" {
  description = "Enable Redshift deployment (set to false for budget mode)"
  type        = bool
  default     = false
}

# -----------------
# Tagging
# -----------------

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------
# Cost Control
# -----------------

variable "budget_limit_dollars" {
  description = "Monthly budget limit in dollars for cost alerts"
  type        = number
  default     = 5
}

variable "budget_alert_threshold_percent" {
  description = "Budget threshold percentage for alerts (e.g., 80 for 80%)"
  type        = number
  default     = 80
  
  validation {
    condition     = var.budget_alert_threshold_percent > 0 && var.budget_alert_threshold_percent <= 100
    error_message = "Threshold must be between 1 and 100 percent."
  }
}

variable "budget_alert_email" {
  description = "Email address for budget alerts"
  type        = string
  default     = ""
}