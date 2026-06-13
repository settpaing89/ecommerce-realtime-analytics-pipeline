# E-Commerce Real-Time Analytics Pipeline

An end-to-end data engineering pipeline on AWS that processes e-commerce transactions through a medallion architecture (Bronze → Silver → Gold), with automated orchestration, serverless querying, and interactive dashboards.

**Live dashboard:** [Tableau Public](https://public.tableau.com/views/ecommerce-analytics-dashboard/Dashboard1)

---

## Architecture

```
Data Generation → Lambda (Ingest → S3 Bronze) → Glue Crawler
    → ETL (Bronze → Silver → Gold) → Athena → Tableau
```

Orchestrated by Step Functions, triggered daily via EventBridge, monitored via CloudWatch.

**Medallion layers:**
- **Bronze** — raw ingested data, partitioned by date, immutable
- **Silver** — deduplicated, type-safe, quality-flagged
- **Gold** — pre-aggregated tables (daily sales, customer LTV, product metrics)

---

## Tech Stack

| Layer | Tools |
|-------|-------|
| Storage | AWS S3 (3 buckets) |
| Ingestion | AWS Lambda (Python 3.9) |
| Cataloging | AWS Glue Crawler + Data Catalog |
| Querying | AWS Athena (serverless SQL) |
| Orchestration | AWS Step Functions + EventBridge |
| Monitoring | AWS CloudWatch |
| Infrastructure | Terraform 1.6+ |
| Processing | Python, Pandas, Boto3, Parquet/Snappy |
| Visualization | Tableau Public, Plotly |
| CI/CD | GitHub Actions |

---

## Prerequisites

- AWS account with admin access
- AWS CLI configured (`aws configure`)
- Terraform 1.6+
- Python 3.9+

---

## Setup

### 1. Clone and install dependencies

```bash
git clone https://github.com/settpaing89/ecommerce-realtime-analytics-pipeline.git
cd ecommerce-realtime-analytics-pipeline

python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Deploy infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
terraform output > ../config/aws_resources.txt
cd ..
```

This creates S3 buckets, Lambda, Glue database/crawler, Athena workgroup, Step Functions state machine, CloudWatch log groups, and IAM roles.

### 3. Generate sample data

```bash
python src/data_generation/generate_data.py
# Produces 5,000 orders, 1,000 customers, 200 products (60 days)
```

### 4. Upload to S3 Bronze layer

```bash
export BRONZE_BUCKET=$(cd terraform && terraform output -raw bronze_bucket_name)

aws s3 cp data/bronze/orders.parquet    s3://$BRONZE_BUCKET/orders/year=2025/month=01/
aws s3 cp data/bronze/customers.parquet s3://$BRONZE_BUCKET/customers/year=2025/month=01/
aws s3 cp data/bronze/products.parquet  s3://$BRONZE_BUCKET/products/year=2025/month=01/
```

### 5. Run the pipeline

```bash
# Via Step Functions (automated)
./scripts/trigger_pipeline.sh

# Or manually
python src/processing/transform_bronze_to_silver.py
python src/processing/transform_silver_to_gold.py
```

### 6. Query with Athena

```bash
export GOLD_BUCKET=$(cd terraform && terraform output -raw gold_bucket_name)

aws athena start-query-execution \
  --query-string "SELECT * FROM daily_sales_summary LIMIT 10" \
  --query-execution-context Database=ecommerce_analytics_dev \
  --result-configuration OutputLocation=s3://$GOLD_BUCKET/athena-results/
```

### 7. Generate dashboards

```bash
# Export CSVs for Tableau
./scripts/export_data_for_dashboards.sh

# Or generate local HTML dashboard
python src/dashboards/generate_html_dashboard.py
open dashboards/ecommerce_dashboard.html
```

---

## Sample Queries

```sql
-- Revenue trend (rolling 30-day)
SELECT order_date, total_revenue,
    SUM(total_revenue) OVER (ORDER BY order_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS rolling_30d
FROM daily_sales_summary
ORDER BY order_date DESC;

-- Customer segments
SELECT segment, COUNT(*) AS customers, ROUND(AVG(lifetime_value), 2) AS avg_ltv
FROM customer_lifetime_value
GROUP BY segment ORDER BY avg_ltv DESC;

-- Top products
SELECT product_name, category, total_revenue, units_sold, profit_margin
FROM product_performance
ORDER BY total_revenue DESC LIMIT 20;
```

---

## Testing

```bash
# Unit tests
pytest tests/ -v

# With coverage
pytest tests/ --cov=src --cov-report=html

# Lint and format
flake8 src/ tests/
black src/ tests/

# Terraform validation
cd terraform && terraform fmt -check && terraform validate && cd ..
```

---

## CI/CD

GitHub Actions runs on every push/PR to `main`:

| Job | What it does |
|-----|-------------|
| Run Tests | flake8, black, pytest |
| Terraform Validation | fmt, init, validate |
| Security Scan | Checkov static analysis |

Run CI checks locally before pushing:

```bash
source venv/bin/activate
flake8 src/ --count --max-complexity=10 --max-line-length=127 --statistics
black --check src/
pytest tests/ -v --cov=src --cov-report=term-missing
cd terraform && terraform fmt -check -recursive . && terraform validate && cd ..
```

Workflow files: [.github/workflows/ci.yml](.github/workflows/ci.yml), [.github/workflows/test_lambda.yml](.github/workflows/test_lambda.yml)

---

## Troubleshooting

**Terraform apply fails with permission denied**
```bash
aws sts get-caller-identity  # verify credentials
```

**Athena returns no results**
```bash
# Repair partitions
aws athena start-query-execution \
  --query-string "MSCK REPAIR TABLE daily_sales_summary" \
  --query-execution-context Database=ecommerce_analytics_dev
```

**Lambda times out**
```bash
aws logs tail /aws/lambda/ecommerce-analytics-dev-ingestion --follow
```

**Step Functions execution fails**
```bash
aws stepfunctions describe-execution --execution-arn <ARN>
```

**High Athena costs** — always filter on partition columns (`year`, `month`) rather than `order_date` to avoid full scans.

---

## Cost

~$0.05/month (S3 + Athena queries). All other services stay within AWS free tier at this scale.

---

## Contact

Aung Sett Paing — asp881999@gmail.com  
[LinkedIn](https://www.linkedin.com/in/toaungsettpaing/) | [GitHub](https://github.com/settpaing89)
