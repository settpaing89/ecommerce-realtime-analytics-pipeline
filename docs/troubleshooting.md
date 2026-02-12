# Troubleshooting Guide

Common issues and their solutions for the E-Commerce Analytics Pipeline.

---

## 🔍 Quick Diagnosis

### System Health Check

```bash
# Run this script to diagnose issues
cat > scripts/health_check.sh << 'EOF'
#!/bin/bash

echo "🏥 System Health Check"
echo "====================="

# 1. AWS Credentials
echo -n "AWS Credentials: "
if aws sts get-caller-identity &>/dev/null; then
    echo "✅ OK"
else
    echo "❌ FAILED - Run 'aws configure'"
fi

# 2. Terraform State
echo -n "Terraform State: "
if [ -f "terraform/terraform.tfstate" ]; then
    echo "✅ OK"
else
    echo "❌ FAILED - Run 'terraform apply'"
fi

# 3. S3 Buckets
echo -n "S3 Buckets: "
BUCKET_COUNT=$(aws s3 ls | grep ecommerce-analytics | wc -l | tr -d ' ')
if [ "$BUCKET_COUNT" -eq "3" ]; then
    echo "✅ OK (3 buckets)"
else
    echo "❌ FAILED - Expected 3, found $BUCKET_COUNT"
fi

# 4. Glue Database
echo -n "Glue Database: "
if aws glue get-database --name ecommerce_analytics_dev &>/dev/null; then
    echo "✅ OK"
else
    echo "❌ FAILED - Database not found"
fi

# 5. Data Files
echo -n "Local Data: "
if [ -d "data/bronze" ] && [ "$(ls -A data/bronze)" ]; then
    echo "✅ OK ($(ls data/bronze | wc -l) files)"
else
    echo "❌ FAILED - Run data generation"
fi

echo "====================="
EOF

chmod +x scripts/health_check.sh
./scripts/health_check.sh
```

---

## 🐛 Common Issues

### 1. AWS Authentication Errors

#### Issue: "Unable to locate credentials"

```bash
Error: Unable to locate credentials. You can configure credentials 
by running "aws configure".
```

**Solutions:**

**A. Configure AWS CLI:**
```bash
aws configure

# Enter your credentials:
AWS Access Key ID: AKIA...
AWS Secret Access Key: ...
Default region: us-east-1
Default output format: json
```

**B. Verify credentials file:**
```bash
# Check if file exists
ls -la ~/.aws/credentials

# View contents (be careful - contains secrets!)
cat ~/.aws/credentials

# Should contain:
# [default]
# aws_access_key_id = AKIA...
# aws_secret_access_key = ...
```

**C. Test credentials:**
```bash
aws sts get-caller-identity

# Expected output:
# {
#   "UserId": "AIDA...",
#   "Account": "123456789012",
#   "Arn": "arn:aws:iam::123456789012:user/your-user"
# }
```

---

#### Issue: "The security token included in the request is expired"

```bash
Error: The security token included in the request is expired
```

**Solutions:**

```bash
# If using temporary credentials (STS), refresh them
aws sts get-session-token

# If using regular IAM user, reconfigure
aws configure

# Clear cached credentials
rm -rf ~/.aws/cli/cache/
```

---

### 2. Terraform Issues

#### Issue: "Error acquiring the state lock"

```bash
Error: Error acquiring the state lock
Lock Info:
  ID:        abc-123-def
  Path:      terraform.tfstate
  Operation: OperationTypeApply
```

**Solutions:**

```bash
# Force unlock (use carefully!)
cd terraform
terraform force-unlock abc-123-def

# Or wait 5 minutes for automatic unlock

# Or delete local lock file (last resort)
rm .terraform/terraform.tfstate.lock.info
```

---

#### Issue: "Resource already exists"

```bash
Error: Error creating S3 bucket: BucketAlreadyExists
```

**Solutions:**

**A. Import existing resource:**
```bash
terraform import module.s3_data_lake.aws_s3_bucket.bronze \
  ecommerce-analytics-dev-bronze-123456789012
```

**B. Or destroy and recreate:**
```bash
terraform destroy
terraform apply
```

**C. Or manually delete in AWS Console:**
```
AWS Console → S3 → Select bucket → Delete
# Then run terraform apply
```

---

#### Issue: "No valid credential sources found"

```bash
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**Solution:**
```bash
# Set environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"

# Or use AWS CLI profile
export AWS_PROFILE=default

# Then run terraform
terraform apply
```

---

### 3. Data Generation Issues

#### Issue: "ModuleNotFoundError: No module named 'faker'"

```bash
ModuleNotFoundError: No module named 'faker'
```

**Solutions:**

```bash
# Activate virtual environment
source venv/bin/activate

# Install packages
pip install -r requirements.txt

# Verify installation
pip list | grep faker

# If still fails, install directly
pip install faker==22.0.0 pyarrow==14.0.1
```

---

#### Issue: "Permission denied: data/bronze"

```bash
PermissionError: [Errno 13] Permission denied: 'data/bronze'
```

**Solutions:**

```bash
# Create directory with proper permissions
mkdir -p data/bronze
chmod 755 data/bronze

# Or run with sudo (not recommended)
sudo python src/data_generation/generate_data.py

# Better: Fix ownership
sudo chown -R $USER:$USER data/
```

---

### 4. S3 Upload Issues

#### Issue: "Access Denied" when uploading

```bash
upload failed: s3://bucket/file.parquet An error occurred (AccessDenied)
```

**Solutions:**

**A. Check IAM permissions:**
```bash
# Verify your identity
aws sts get-caller-identity

# Check bucket policy
aws s3api get-bucket-policy --bucket $BRONZE_BUCKET

# Try with different profile
aws s3 cp file.parquet s3://$BRONZE_BUCKET/ --profile admin
```

**B. Verify bucket exists:**
```bash
# List buckets
aws s3 ls | grep ecommerce

# If not found, deploy infrastructure
cd terraform && terraform apply
```

**C. Check bucket name:**
```bash
# Verify environment variable
echo $BRONZE_BUCKET

# Should show: ecommerce-analytics-dev-bronze-123456789012

# If empty, reload
source config/aws_resources.sh
```

---

#### Issue: "NoSuchBucket" error

```bash
An error occurred (NoSuchBucket) when calling the PutObject operation
```

**Solutions:**

```bash
# List all buckets
aws s3 ls

# Recreate bucket
cd terraform
terraform apply -target=module.s3_data_lake

# Or create manually
aws s3 mb s3://$BRONZE_BUCKET
```

---

### 5. Glue Crawler Issues

#### Issue: "Crawler not finding tables"

```bash
# Crawler runs but creates no tables
```

**Solutions:**

**A. Check S3 data exists:**
```bash
aws s3 ls s3://$BRONZE_BUCKET/ --recursive

# Should show files like:
# customers/year=2025/month=01/customers.parquet
```

**B. Check crawler configuration:**
```bash
aws glue get-crawler --name $GLUE_CRAWLER

# Verify:
# - Targets.S3Targets[0].Path matches your bucket
# - State is not "RUNNING" (wait if it is)
```

**C. Check crawler logs:**
```bash
# Get last run details
aws glue get-crawler-metrics --crawler-name-list $GLUE_CRAWLER

# Check CloudWatch logs
aws logs tail /aws-glue/crawlers --follow
```

**D. Restart crawler:**
```bash
# Stop crawler (if running)
aws glue stop-crawler --name $GLUE_CRAWLER

# Wait 30 seconds
sleep 30

# Start again
aws glue start-crawler --name $GLUE_CRAWLER
```

---

#### Issue: "Crawler creates wrong schema"

```bash
# Tables exist but columns are incorrect
```

**Solutions:**

```bash
# Delete tables
aws glue delete-table --database-name $GLUE_DATABASE --name customers
aws glue delete-table --database-name $GLUE_DATABASE --name products
aws glue delete-table --database-name $GLUE_DATABASE --name orders
aws glue delete-table --database-name $GLUE_DATABASE --name events

# Rerun crawler
aws glue start-crawler --name $GLUE_CRAWLER

# Verify schema
aws glue get-table --database-name $GLUE_DATABASE --name orders \
  --query 'Table.StorageDescriptor.Columns[].{Name:Name,Type:Type}' \
  --output table
```

---

### 6. Athena Query Issues

#### Issue: "Database not found"

```sql
FAILED: SemanticException [Error 10072]: Database does not exist: ecommerce_analytics_dev
```

**Solutions:**

```bash
# List databases
aws glue get-databases --query 'DatabaseList[].Name'

# If not found, check Glue database exists
aws glue get-database --name ecommerce_analytics_dev

# If error, recreate
cd terraform
terraform apply -target=aws_glue_catalog_database.ecommerce_db
```

---

#### Issue: "Table not found"

```sql
FAILED: SemanticException [Error 10001]: Table not found 'orders'
```

**Solutions:**

```bash
# List tables
aws glue get-tables --database-name $GLUE_DATABASE \
  --query 'TableList[].Name'

# If empty, run crawler
aws glue start-crawler --name $GLUE_CRAWLER

# Wait 2-3 minutes, then verify
aws glue get-tables --database-name $GLUE_DATABASE
```

---

#### Issue: "HIVE_CANNOT_OPEN_SPLIT"

```sql
HIVE_CANNOT_OPEN_SPLIT: Error opening Hive split 
s3://bucket/file.parquet (Offset: 0, Length: 1234)
```

**Solutions:**

**A. Check file exists:**
```bash
aws s3 ls s3://$BRONZE_BUCKET/orders/ --recursive
```

**B. Verify file format:**
```bash
# Download file
aws s3 cp s3://$BRONZE_BUCKET/orders/year=2025/month=01/orders.parquet /tmp/

# Check if valid parquet
pip install parquet-tools
parquet-tools schema /tmp/orders.parquet
```

**C. Regenerate and reupload:**
```bash
python src/data_generation/generate_data.py
aws s3 cp data/bronze/orders.parquet s3://$BRONZE_BUCKET/orders/year=2025/month=01/
```

---

### 7. Cost Issues

#### Issue: "Unexpected charges"

```bash
# AWS bill higher than expected
```

**Solutions:**

**A. Check what's running:**
```bash
# Check EC2 instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType]'

# Check Redshift clusters
aws redshift describe-clusters \
  --query 'Clusters[].[ClusterIdentifier,NodeType,NumberOfNodes]'

# Check RDS databases
aws rds describe-db-instances \
  --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass]'

# If any found, terminate them immediately!
```

**B. Check S3 storage:**
```bash
# Get storage size
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=$BRONZE_BUCKET Name=StorageType,Value=StandardStorage \
  --start-time $(date -u -v-1d +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Average

# If too large, delete old data
aws s3 rm s3://$BRONZE_BUCKET/old-folder/ --recursive
```

**C. Check costs by service:**
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

**D. Emergency shutdown:**
```bash
# Destroy everything
cd terraform
terraform destroy
# Type 'yes'

# Verify
aws s3 ls | grep ecommerce  # Should be empty
aws lambda list-functions | grep ecommerce  # Should be empty
```

---

### 8. Performance Issues

#### Issue: "Athena queries too slow"

```bash
# Query takes >10 seconds
```

**Solutions:**

**A. Use partitions:**
```sql
-- BAD: Scans entire table
SELECT * FROM orders WHERE order_date = '2025-01-27';

-- GOOD: Uses partitions
SELECT * FROM orders 
WHERE year='2025' AND month='01' AND day='27';
```

**B. Select only needed columns:**
```sql
-- BAD: Reads all columns
SELECT * FROM orders;

-- GOOD: Reads only needed columns
SELECT order_id, total_amount FROM orders;
```

**C. Use LIMIT:**
```sql
-- Add LIMIT for testing
SELECT * FROM orders LIMIT 100;
```

---

#### Issue: "Data generation takes too long"

```bash
# Takes >5 minutes to generate data
```

**Solutions:**

```bash
# Reduce number of records (in generate_data.py)
NUM_CUSTOMERS = 500   # Instead of 1000
NUM_ORDERS = 5000     # Instead of 10000
NUM_EVENTS = 10000    # Instead of 20000

# Or use multiprocessing
# (Requires code changes - see advanced optimization)
```

---

## 🔧 Advanced Troubleshooting

### Debug Mode

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform apply

# Enable AWS CLI debug
aws s3 ls --debug

# Enable Python verbose output
python -u src/data_generation/generate_data.py
```

### Check CloudWatch Logs

```bash
# Lambda logs
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --follow

# Glue crawler logs
aws logs tail /aws-glue/crawlers --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/$LAMBDA_FUNCTION \
  --filter-pattern "ERROR"
```

### Verify IAM Permissions

```bash
# Check your permissions
aws iam get-user

# Simulate policy
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:user/your-user \
  --action-names s3:PutObject s3:GetObject \
  --resource-arns arn:aws:s3:::$BRONZE_BUCKET/*
```

---

## 🆘 Emergency Procedures

### Complete Reset

```bash
# 1. Destroy all AWS resources
cd terraform
terraform destroy
# Type 'yes'

# 2. Delete local data
rm -rf data/bronze/*
rm -rf data/silver/*
rm -rf data/gold/*

# 3. Clear Terraform state
rm -rf .terraform/
rm terraform.tfstate*

# 4. Reinstall Python packages
pip install -r requirements.txt --force-reinstall

# 5. Start fresh
terraform init
terraform apply
python src/data_generation/generate_data.py
./scripts/upload_to_s3.sh
```

### Rollback to Last Working State

```bash
# If you have Git commits
git log --oneline  # Find last working commit
git checkout abc123  # Checkout that commit

# Redeploy infrastructure
cd terraform
terraform apply

# Or use Terraform state backups
terraform state pull > backup.tfstate
# If needed: terraform state push backup.tfstate
```

---

## 📞 Getting Help

### Before Asking for Help

Gather this information:

```bash
# 1. System info
uname -a
python --version
terraform --version
aws --version

# 2. AWS account
aws sts get-caller-identity

# 3. Error message (full output)
# Copy entire error, not just last line

# 4. What you were doing
# Exact command that failed

# 5. What you tried
# List troubleshooting steps already attempted
```

### Where to Get Help

1. **GitHub Issues**: Open an issue with above info
2. **AWS Support**: For AWS-specific issues
3. **Stack Overflow**: Tag `aws`, `terraform`, `data-engineering`
4. **Project Docs**: Review [Setup Guide](setup_guide.md), [Architecture](architecture.md)

---

## ✅ Prevention Checklist

Avoid issues by following these best practices:

- [ ] Always activate `venv` before running Python
- [ ] Load `aws_resources.sh` in new terminal sessions
- [ ] Run `terraform plan` before `apply`
- [ ] Check costs daily with `./scripts/check_costs.sh`
- [ ] Commit working code frequently
- [ ] Test in small increments
- [ ] Read error messages carefully (don't just copy-paste commands)
- [ ] Keep AWS CLI and Terraform updated

---

**Still stuck?** Open an issue on GitHub with:
- Error message
- Steps to reproduce
- System info
- What you've tried

We're here to help! 🚀