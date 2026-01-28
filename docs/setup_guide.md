# Setup Guide

Complete installation and configuration guide for the E-Commerce Analytics Pipeline.

---

## 📋 Prerequisites

### Required Software

| Software | Minimum Version | Installation | Verification |
|----------|----------------|--------------|--------------|
| **AWS CLI** | 2.x | [Download](https://aws.amazon.com/cli/) | `aws --version` |
| **Python** | 3.9+ | [Download](https://python.org) | `python --version` |
| **Terraform** | 1.6+ | [Download](https://terraform.io) | `terraform --version` |
| **Git** | 2.x | [Download](https://git-scm.com) | `git --version` |
| **Docker** | 20.x+ | [Download](https://docker.com) | `docker --version` |

### AWS Account Setup

1. **Create AWS Account**
   ```
   → Visit: https://aws.amazon.com/free/
   → Sign up for free tier
   → Verify email and payment method
   ```

2. **Create IAM User**
   ```bash
   # In AWS Console:
   IAM → Users → Add User
   
   Username: data-engineer
   Access type: ☑ Programmatic access
   
   Permissions: AdministratorAccess (for development)
   # Production: Use least-privilege policies
   ```

3. **Save Credentials**
   ```
   Access Key ID: AKIA...
   Secret Access Key: wJal...
   
   ⚠️ Save these securely - shown only once!
   ```

4. **Configure AWS CLI**
   ```bash
   aws configure
   
   AWS Access Key ID: [paste your key]
   AWS Secret Access Key: [paste your secret]
   Default region: us-east-1
   Default output format: json
   ```

5. **Verify Configuration**
   ```bash
   aws sts get-caller-identity
   
   # Should show:
   # {
   #   "UserId": "AIDA...",
   #   "Account": "123456789012",
   #   "Arn": "arn:aws:iam::123456789012:user/data-engineer"
   # }
   ```

### Cost Protection Setup

```bash
# Set up budget alert
AWS Console → Billing → Budgets → Create budget

Budget name: Portfolio-Project
Amount: $5.00
Alert threshold: 80% ($4.00)
Email: your-email@example.com
```

---

## 🚀 Installation Steps

### Step 1: Clone Repository (2 min)

```bash
# Clone the project
git clone https://github.com/YOUR_USERNAME/ecommerce-realtime-analytics-pipeline.git

# Navigate to directory
cd ecommerce-realtime-analytics-pipeline

# Verify structure
ls -la
```

**Expected output:**
```
drwxr-xr-x  terraform/
drwxr-xr-x  src/
drwxr-xr-x  scripts/
-rw-r--r--  README.md
-rw-r--r--  requirements.txt
```

### Step 2: Python Environment (3 min)

```bash
# Create virtual environment
python -m venv venv

# Activate (macOS/Linux)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

# Verify installation
pip list | grep -E "boto3|faker|pandas|pyarrow"
```

**Expected packages:**
```
boto3         1.34.10
faker         22.0.0
pandas        2.1.4
pyarrow       14.0.1
```

### Step 3: Terraform Setup (5 min)

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Expected output:
# Initializing modules...
# Initializing the backend...
# Initializing provider plugins...
# Terraform has been successfully initialized!

# Validate configuration
terraform validate

# Expected output:
# Success! The configuration is valid.

# Preview infrastructure
terraform plan

# Expected output:
# Plan: 20 to add, 0 to change, 0 to destroy.
```

**What gets created:**

```
Resources (20 total):
├── S3 Buckets (3)
│   ├── Bronze layer bucket
│   ├── Silver layer bucket
│   └── Gold layer bucket
├── S3 Configurations (5)
│   ├── Versioning (3)
│   └── Lifecycle policies (2)
├── Lambda Resources (4)
│   ├── Function
│   ├── IAM role
│   ├── IAM policy
│   └── CloudWatch log group
├── Glue Resources (5)
│   ├── Database
│   ├── Crawler
│   ├── IAM role
│   └── IAM policies (2)
└── Athena Resources (3)
    ├── Workgroup
    ├── Output location
    └── CloudWatch dashboard
```

### Step 4: Deploy Infrastructure (5 min)

```bash
# Deploy to AWS
terraform apply

# Review the plan, then type: yes

# Wait 3-5 minutes for completion

# Expected output:
# Apply complete! Resources: 20 added, 0 changed, 0 destroyed.
# 
# Outputs:
# bronze_bucket = "ecommerce-analytics-dev-bronze-123456789012"
# ...
```

**Save resource names:**
```bash
# Save to config file
terraform output -raw env_vars_export > ../config/aws_resources.sh

# Make executable
chmod +x ../config/aws_resources.sh

# Load environment variables
cd ..
source config/aws_resources.sh
```

### Step 5: Verify Deployment (2 min)

```bash
# Check S3 buckets
aws s3 ls | grep ecommerce-analytics

# Expected output:
# ecommerce-analytics-dev-bronze-123456789012
# ecommerce-analytics-dev-silver-123456789012
# ecommerce-analytics-dev-gold-123456789012

# Check Lambda function
aws lambda list-functions --query 'Functions[?contains(FunctionName, `ecommerce`)].FunctionName'

# Expected output:
# ["ecommerce-analytics-dev-ingestion"]

# Check Glue database
aws glue get-databases --query 'DatabaseList[?Name==`ecommerce_analytics_dev`].Name'

# Expected output:
# ["ecommerce_analytics_dev"]

# Check costs (should be $0.00)
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
  --output text

# Expected: 0.0000000000 (or very close)
```

---

## 📊 Generate & Upload Data

### Step 6: Generate Sample Data (1 min)

```bash
# Generate realistic e-commerce data
python src/data_generation/generate_data.py

# Expected output:
# ============================================================
# E-COMMERCE DATA GENERATOR
# ============================================================
# 
# Generating 1000 customers...
# ✓ Generated 1000 customers
# Generating 100 products...
# ✓ Generated 100 products
# ...
# ✅ SUCCESS!
# Generated 4 datasets with 31,100 total records
# Total size: 3.96 MB

# Verify files created
ls -lh data/bronze/

# Expected output:
# customers.parquet  (~180KB)
# products.parquet   (~20KB)
# orders.parquet     (~1.5MB)
# events.parquet     (~2.3MB)
```

### Step 7: Upload to S3 (1 min)

```bash
# Load environment variables (if not already loaded)
source config/aws_resources.sh

# Create upload script directory
mkdir -p scripts

# Upload data
aws s3 cp data/bronze/customers.parquet \
  s3://$BRONZE_BUCKET/customers/year=2025/month=01/customers.parquet

aws s3 cp data/bronze/products.parquet \
  s3://$BRONZE_BUCKET/products/year=2025/month=01/products.parquet

aws s3 cp data/bronze/orders.parquet \
  s3://$BRONZE_BUCKET/orders/year=2025/month=01/orders.parquet

aws s3 cp data/bronze/events.parquet \
  s3://$BRONZE_BUCKET/events/year=2025/month=01/events.parquet

# Verify upload
aws s3 ls s3://$BRONZE_BUCKET/ --recursive --human-readable

# Expected output:
# 2025-01-27 14:30:00  180.5 KiB customers/year=2025/month=01/customers.parquet
# 2025-01-27 14:30:01   20.1 KiB products/year=2025/month=01/products.parquet
# 2025-01-27 14:30:02    1.5 MiB orders/year=2025/month=01/orders.parquet
# 2025-01-27 14:30:03    2.3 MiB events/year=2025/month=01/events.parquet
```

### Step 8: Catalog Data with Glue (3 min)

```bash
# Start Glue Crawler
aws glue start-crawler --name $GLUE_CRAWLER

# No output = success

# Wait 2-3 minutes, check status
aws glue get-crawler \
  --name $GLUE_CRAWLER \
  --query 'Crawler.State' \
  --output text

# Expected: RUNNING (then READY when done)

# Monitor progress (optional)
watch -n 10 'aws glue get-crawler --name $GLUE_CRAWLER --query Crawler.State --output text'

# When READY, verify tables created
aws glue get-tables \
  --database-name $GLUE_DATABASE \
  --query 'TableList[].Name' \
  --output table

# Expected output:
# -------------
# | GetTables |
# +-----------+
# | customers |
# | events    |
# | orders    |
# | products  |
# +-----------+
```

### Step 9: Test Query with Athena (1 min)

```bash
# Open Athena console
echo "https://console.aws.amazon.com/athena/home?region=us-east-1#/query-editor"

# Or query via CLI
aws athena start-query-execution \
  --query-string "SELECT COUNT(*) as total_orders FROM orders" \
  --query-execution-context Database=$GLUE_DATABASE \
  --result-configuration OutputLocation=s3://$GOLD_BUCKET/athena-results/ \
  --work-group $ATHENA_WORKGROUP \
  --query 'QueryExecutionId' \
  --output text

# Save execution ID, then get results
EXECUTION_ID="paste-id-here"

aws athena get-query-results \
  --query-execution-id $EXECUTION_ID \
  --output table

# Expected: Shows count of orders (~10,000)
```

---

## ✅ Verification Checklist

After setup, verify everything works:

```bash
# ✓ AWS CLI configured
aws sts get-caller-identity

# ✓ Python environment active
which python  # Should show venv path

# ✓ Terraform deployed successfully
cd terraform && terraform show && cd ..

# ✓ S3 buckets exist
aws s3 ls | grep ecommerce-analytics | wc -l  # Should be 3

# ✓ Data uploaded
aws s3 ls s3://$BRONZE_BUCKET/ --recursive | wc -l  # Should be 4

# ✓ Glue tables created
aws glue get-tables --database-name $GLUE_DATABASE | grep -c Name  # Should be 4

# ✓ Athena workgroup exists
aws athena get-work-group --work-group $ATHENA_WORKGROUP

# ✓ Current costs low
./scripts/check_costs.sh  # Should show ~$0.02
```

**All checks passed?** ✅ You're ready to continue!

---

## 🔧 Common Setup Issues

### Issue 1: AWS Credentials Not Found

**Error:**
```
Unable to locate credentials. You can configure credentials by running "aws configure".
```

**Solution:**
```bash
# Reconfigure AWS CLI
aws configure

# Verify credentials file exists
cat ~/.aws/credentials

# Should contain:
# [default]
# aws_access_key_id = AKIA...
# aws_secret_access_key = ...
```

### Issue 2: Terraform Init Fails

**Error:**
```
Error: Failed to query available provider packages
```

**Solution:**
```bash
# Check internet connection
ping terraform.io

# Remove lock file
rm -rf terraform/.terraform.lock.hcl

# Reinitialize
cd terraform
terraform init
```

### Issue 3: Python Package Installation Fails

**Error:**
```
ERROR: Could not find a version that satisfies the requirement...
```

**Solution:**
```bash
# Upgrade pip
pip install --upgrade pip

# Install packages one by one
pip install boto3
pip install faker
pip install pandas
pip install pyarrow

# Or reinstall everything
pip install -r requirements.txt --force-reinstall
```

### Issue 4: Glue Crawler Not Finding Tables

**Error:**
```
Tables not appearing after crawler run
```

**Solution:**
```bash
# Check S3 data exists
aws s3 ls s3://$BRONZE_BUCKET/ --recursive

# Check crawler logs
aws glue get-crawler --name $GLUE_CRAWLER

# Restart crawler
aws glue stop-crawler --name $GLUE_CRAWLER
sleep 30
aws glue start-crawler --name $GLUE_CRAWLER
```

### Issue 5: Cost Higher Than Expected

**Solution:**
```bash
# Check running resources
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
aws redshift describe-clusters

# Should be empty - if not, terminate them

# Check S3 storage
aws s3 ls s3://$BRONZE_BUCKET/ --recursive --human-readable --summarize

# Should be ~4MB total

# Destroy and recreate if needed
cd terraform
terraform destroy
terraform apply
```

---

## 🧹 Cleanup (When Done)

### Temporary Cleanup (Keep Infrastructure)

```bash
# Delete S3 data only
aws s3 rm s3://$BRONZE_BUCKET/ --recursive
aws s3 rm s3://$SILVER_BUCKET/ --recursive
aws s3 rm s3://$GOLD_BUCKET/ --recursive

# Delete Glue tables
aws glue delete-table --database-name $GLUE_DATABASE --name customers
aws glue delete-table --database-name $GLUE_DATABASE --name products
aws glue delete-table --database-name $GLUE_DATABASE --name orders
aws glue delete-table --database-name $GLUE_DATABASE --name events
```

### Full Cleanup (Destroy Everything)

```bash
# Destroy all AWS resources
cd terraform
terraform destroy

# Type 'yes' when prompted

# Verify deletion
aws s3 ls | grep ecommerce-analytics  # Should be empty
aws lambda list-functions | grep ecommerce  # Should be empty
```

**Cost after cleanup:** $0.00

---

## 📚 Next Steps

After successful setup:

1. ✅ [Explore the Architecture](architecture.md)
2. ✅ [Review Data Catalog](data_catalog.md)
3. ✅ [Learn Deployment Process](deployment.md)
4. ✅ [Run Sample Queries](../src/warehouse/analytics_queries.sql)

---

**Setup complete!** 🎉 You now have a fully functional cloud data pipeline.

*Questions? See [Troubleshooting Guide](troubleshooting.md)*