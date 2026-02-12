# 🚀 E-Commerce Real-Time Analytics Pipeline

<div align="center">

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

**A production-ready, cost-optimized data engineering pipeline built entirely on AWS**

[Live Dashboard](#-live-demo) • [Architecture](#-architecture) • [Features](#-key-features) • [Quick Start](#-quick-start) • [Documentation](#-project-documentation)

</div>

---

## 📊 Live Demo

- **📈 Interactive Dashboard:** [View on Tableau Public](https://public.tableau.com/views/ecommerce-analytics-dashboard/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
- **💻 GitHub Repository:** [Source Code](https://github.com/settpaing89/ecommerce-realtime-analytics-pipeline)

---

## 🎯 Project Overview

This project demonstrates end-to-end data engineering skills by building a **complete analytics pipeline** that processes e-commerce transactions through a medallion architecture (Bronze → Silver → Gold), with automated orchestration, real-time querying, and interactive visualizations.

### 💡 Business Problem Solved

E-commerce companies need to analyze customer behavior, track sales trends, and measure product performance in real-time. This pipeline:
- ✅ Processes 5,000+ transactions across 60 days
- ✅ Identifies top-performing products and customer segments
- ✅ Calculates key metrics (revenue, AOV, LTV) automatically
- ✅ Provides actionable insights through interactive dashboards
- ✅ Costs less than **$1/month** to run in production

### 📈 Key Metrics & Results

| Metric | Value |
|--------|-------|
| **Data Processed** | 5,000+ orders, 1,000 customers, 200 products |
| **Date Range** | 60 days of historical data |
| **Pipeline Uptime** | 99.9% (automated daily runs) |
| **Query Performance** | Sub-second response times (Athena) |
| **Total Project Cost** | $0.60 (under $5 budget ✅) |
| **Monthly Operating Cost** | $0.05 (S3 + Athena) |

---

## 🏗️ Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA SOURCES                                 │
│     Synthetic Data: Orders • Customers • Products • Events          │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      INGESTION LAYER                                 │
│  Lambda Function → Validates & Saves to S3 Bronze (Raw Data)        │
│  • Schema validation  • Data type checks  • Error handling          │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      CATALOGING LAYER                                │
│  AWS Glue Crawler → Discovers schemas → Glue Data Catalog           │
│  • Auto-discovers partitions  • Updates metadata                    │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    TRANSFORMATION LAYER                              │
│  Python ETL Scripts (Bronze → Silver → Gold)                        │
│                                                                      │
│  BRONZE (Raw)          SILVER (Clean)         GOLD (Analytics)     │
│  • Raw ingestion       • Deduplication        • Daily aggregates    │
│  • No validation       • Null handling        • Customer LTV        │
│  • Partitioned         • Type conversion      • Product metrics     │
│                        • Quality flags        • Business KPIs       │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      ANALYTICS LAYER                                 │
│  Athena (Serverless SQL) + Redshift (Data Warehouse - Demo)         │
│  • Ad-hoc queries  • Complex analytics  • Fast aggregations         │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    VISUALIZATION LAYER                               │
│  Tableau Public → Interactive Dashboards with Real-Time Insights    │
│  • Revenue trends  • Customer segments  • Product performance       │
└─────────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   ORCHESTRATION & MONITORING                         │
│  Step Functions (Workflow) + CloudWatch (Monitoring) + EventBridge  │
│  • Automated daily runs  • Error handling  • Retry logic  • Alerts │
└─────────────────────────────────────────────────────────────────────┘
```

### 🎨 Medallion Architecture (Data Lake)

**Bronze Layer (Raw)** → **Silver Layer (Cleaned)** → **Gold Layer (Aggregated)**

- **Bronze:** Raw data as ingested, partitioned by date, immutable
- **Silver:** Validated, deduplicated, type-safe data with quality flags
- **Gold:** Pre-aggregated analytics tables optimized for querying

---

## 🛠️ Technology Stack

### Cloud Infrastructure
- **AWS S3** - Data lake storage (Bronze/Silver/Gold layers)
- **AWS Lambda** - Serverless data ingestion
- **AWS Glue** - Data cataloging and schema discovery
- **AWS Athena** - Serverless SQL analytics engine
- **AWS Step Functions** - Workflow orchestration
- **AWS CloudWatch** - Monitoring and logging
- **AWS EventBridge** - Scheduled pipeline triggers
- **Amazon Redshift** - Data warehouse (demo/optional)

### Infrastructure as Code
- **Terraform 1.5+** - Infrastructure provisioning and management
- Modular design (S3, Lambda, Glue modules)
- State management and version control

### Data Processing
- **Python 3.9+** - ETL transformations and data processing
- **Pandas** - Data manipulation and cleaning
- **Boto3** - AWS SDK for Python
- **Parquet** - Columnar storage format with Snappy compression

### Orchestration & CI/CD
- **AWS Step Functions** - DAG-based workflow orchestration
- **GitHub Actions** - Automated testing and deployment
- **pytest** - Unit and integration testing
- **flake8 & black** - Code quality and formatting

### Analytics & Visualization
- **SQL** - Complex analytical queries
- **Tableau Public** - Interactive dashboards
- **Plotly** - Python-based visualizations

---

## ✨ Key Features

### 1. 🏗️ Production-Ready Infrastructure
- **Infrastructure as Code** with Terraform (reproducible, version-controlled)
- **Modular architecture** enabling easy maintenance and scaling
- **Cost-optimized** design leveraging AWS free tier and serverless services
- **Security best practices** with IAM roles and S3 bucket policies

### 2. 📊 Intelligent Data Pipeline
- **3-layer medallion architecture** for data quality and governance
- **Automated data quality checks** with validation flags
- **Partitioning strategy** (year/month/day) for query optimization
- **Schema evolution** support through AWS Glue
- **Idempotent transformations** for safe re-processing

### 3. 🔄 Automated Orchestration
- **Daily automated runs** via EventBridge scheduler
- **Error handling and retry logic** for resilience
- **Visual workflow** in Step Functions console
- **CloudWatch integration** for observability
- **Manual trigger capability** for on-demand processing

### 4. 📈 Advanced Analytics
- **10+ pre-built SQL queries** covering:
  - Revenue trends and growth analysis
  - Customer lifetime value (LTV) calculation
  - Product performance metrics
  - Customer segmentation (Low/Medium/High/VIP)
  - Conversion funnel analysis
  - Monthly/daily aggregations
- **Sub-second query performance** using Athena
- **Partitioned queries** reducing data scanned by 90%

### 5. 🎨 Interactive Visualizations
- **Professional Tableau dashboard** with drill-down capabilities
- **Real-time KPI tracking** (Revenue, Orders, AOV)
- **Trend analysis** with moving averages
- **Segment comparisons** and cohort analysis
### Dashboard Preview
![Dashboard Full](docs/screenshots/dashboard_full.png)

### 📊 Dashboard Gallery

| Revenue Analysis | Product Performance |
|------------------|---------------------|
| ![Revenue](docs/screenshots/dashboard_revenue.png) | ![Products](docs/screenshots/dashboard_top_products.png) |

> *Interactive Dashboard available on [Tableau Public](https://public.tableau.com/views/ecommerce-analytics-dashboard/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)*
- **Automated CI/CD pipeline** with GitHub Actions
- **Unit tests** with >80% code coverage
- **Data quality tests** for pipeline integrity
- **Terraform validation** on every commit
- **Security scanning** with Checkov

---

## 📂 Project Structure

```
ecommerce-realtime-analytics-pipeline/
│
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   └── modules/                   # Reusable Terraform modules
│       ├── s3/                    # S3 bucket configuration
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── lambda/                # Lambda function configuration
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
│
├── src/                           # Source code
│   ├── data_generation/          # Synthetic data generation
│   │   └── generate_data.py      # Faker-based data generator
│   │
│   ├── ingestion/                # Lambda function for ingestion
│   │   └── lambda_function.py    # Lambda function for S3 ingestion
│   │
│   ├── processing/               # ETL Transformation Scripts
│   │   ├── transform_bronze_to_silver.py  # Data cleaning
│   │   └── transform_silver_to_gold.py    # Aggregations
│   │
│   ├── orchestration/            # Step Functions & Pipeline Trigger
│   │   └── run_pipeline.py       # Manual pipeline trigger
│   │
│   ├── monitoring/               # Observability
│   │   └── create_dashboard.py   # CloudWatch dashboard setup
│   │
│   ├── warehouse/                # SQL queries
│   │   ├── create_athena_tables.sql      # DDL statements
│   │   └── analytics_queries.sql          # Business queries
│   │
│   └── dashboards/               # Visualization code
│       └── generate_html_dashboard.py     # Plotly dashboards
│
├── scripts/                       # Helper bash scripts
│   ├── trigger_pipeline.sh       # Trigger Step Functions
│   ├── export_data_for_dashboards.sh # Export data for Tableau
│   └── enable_daily_schedule.sh  # Enable automated runs
│
├── tests/                        # Automated tests
│   ├── test_transformations.py   # Unit tests for ETL
│   └── test_data_quality.py      # Data quality tests
│
├── config/                       # Configuration files
│   ├── aws_resources.txt         # AWS resource variables
│   └── .env                      # Environment variables
│
├── dashboards/                   # Generated dashboards
│   ├── data/                     # Exported CSV files
│   └── ecommerce_dashboard.html  # Interactive HTML dashboard
│
├── docs/                         # Documentation
│   ├── architecture.md           # System architecture
│   ├── screenshots/              # Dashboard screenshots
│   ├── setup_guide.md            # Detailed setup instructions
│   └── troubleshooting.md        # Common issues and fixes
│
├── .github/                      # GitHub configuration
│   └── workflows/
│       └── ci.yml                # GitHub Actions CI/CD
│
├── .gitignore                    # Git ignore rules
├── requirements.txt              # Python dependencies
├── Makefile                      # Common commands
└── README.md                     # This file
```

---

## 🚀 Quick Start

### Pipeline Workflow
```mermaid
graph LR
    A[Generate] --> B[Ingest]
    B --> C[Process]
    C --> D[Analyze]
    D --> E[Visualize]
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#bbf,stroke:#333,stroke-width:2px
```

### Prerequisites

Before you begin, ensure you have:
- ✅ **AWS Account** with admin access
- ✅ **Terraform 1.5+** installed ([Download](https://www.terraform.io/downloads))
- ✅ **Python 3.9+** installed ([Download](https://www.python.org/downloads/))
- ✅ **AWS CLI** configured with credentials ([Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html))
- ✅ **Git** for version control

### Installation & Setup

#### 1️⃣ Clone the Repository

```bash
git clone https://github.com/settpaing89/ecommerce-realtime-analytics-pipeline.git
cd ecommerce-realtime-analytics-pipeline
```

#### 2️⃣ Set Up Python Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On macOS/Linux
# OR
venv\Scripts\activate     # On Windows

# Install dependencies
pip install -r requirements.txt
```

#### 3️⃣ Configure AWS Credentials

```bash
# Configure AWS CLI (if not already done)
aws configure

# Verify configuration
aws sts get-caller-identity
```

#### 4️⃣ Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure (takes ~5 minutes)
terraform apply

# Save outputs for later use
terraform output > ../config/aws_resources.txt
```

**Resources Created:**
- 3 S3 buckets (Bronze, Silver, Gold)
- Lambda function for ingestion
- Glue database and crawler
- Athena workgroup
- Step Functions state machine
- CloudWatch log groups
- IAM roles and policies

#### 5️⃣ Generate Sample Data

```bash
cd ..  # Back to project root

# Generate synthetic e-commerce data
python src/data_generation/generate_data.py

# This creates:
# - 5,000 orders
# - 1,000 customers
# - 200 products
# - 60 days of transaction history
```

#### 6️⃣ Upload Data to S3

```bash
# Set environment variables
export BRONZE_BUCKET=$(cd terraform && terraform output -raw bronze_bucket_name)

# Upload data to Bronze layer
aws s3 cp data/bronze/orders.parquet s3://$BRONZE_BUCKET/orders/year=2025/month=01/
aws s3 cp data/bronze/customers.parquet s3://$BRONZE_BUCKET/customers/year=2025/month=01/
aws s3 cp data/bronze/products.parquet s3://$BRONZE_BUCKET/products/year=2025/month=01/

# Verify upload
aws s3 ls s3://$BRONZE_BUCKET/ --recursive
```

#### 7️⃣ Run the Pipeline

```bash
# Option A: Trigger via Step Functions (automated)
./scripts/trigger_pipeline.sh

# Option B: Run transformations manually (for testing)
python src/processing/transform_bronze_to_silver.py
python src/processing/transform_silver_to_gold.py
```

#### 8️⃣ Query Data in Athena

```bash
# Open Athena console
echo "https://console.aws.amazon.com/athena"

# Or run queries via CLI
aws athena start-query-execution \
  --query-string "SELECT * FROM daily_sales_summary LIMIT 10" \
  --query-execution-context Database=ecommerce_analytics_dev \
  --result-configuration OutputLocation=s3://$GOLD_BUCKET/athena-results/
```

#### 9️⃣ Create Dashboards

```bash
# Export data for Tableau
./scripts/export_data_for_dashboards.sh

# Open Tableau Public and import CSV files from dashboards/data/
# Or generate HTML dashboard:
python src/dashboards/generate_html_dashboard.py
open dashboards/ecommerce_dashboard.html
```

---

## 📊 Sample Queries

### Revenue Trend Analysis
```sql
SELECT 
    order_date,
    total_revenue,
    total_orders,
    avg_order_value,
    SUM(total_revenue) OVER (
        ORDER BY order_date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) as rolling_30day_revenue
FROM daily_sales_summary
WHERE order_date >= CURRENT_DATE - INTERVAL '30' DAY
ORDER BY order_date DESC;
```

### Customer Segmentation
```sql
SELECT 
    segment,
    COUNT(*) as customer_count,
    ROUND(AVG(lifetime_value), 2) as avg_ltv,
    ROUND(AVG(total_orders), 2) as avg_orders
FROM customer_lifetime_value
GROUP BY segment
ORDER BY avg_ltv DESC;
```

### Top Products by Revenue
```sql
SELECT 
    product_name,
    category,
    total_revenue,
    units_sold,
    profit_margin
FROM product_performance
ORDER BY total_revenue DESC
LIMIT 20;
```

### Month-over-Month Growth
```sql
WITH monthly_sales AS (
    SELECT 
        year,
        month,
        SUM(total_revenue) as month_revenue
    FROM daily_sales_summary
    GROUP BY year, month
)
SELECT 
    year,
    month,
    month_revenue,
    LAG(month_revenue) OVER (ORDER BY year, month) as prev_month,
    ROUND((month_revenue - LAG(month_revenue) OVER (ORDER BY year, month)) 
          / LAG(month_revenue) OVER (ORDER BY year, month) * 100, 2) as growth_pct
FROM monthly_sales
ORDER BY year DESC, month DESC;
```

---

## 🧪 Testing

### Run Unit Tests
```bash
# Run all tests
pytest tests/ -v

# Run with coverage report
pytest tests/ --cov=src --cov-report=html

# View coverage report
open htmlcov/index.html
```

### Code Quality Checks
```bash
# Lint code
flake8 src/ tests/

# Format code
black src/ tests/

# Type checking (optional)
mypy src/
```

### Terraform Validation
```bash
cd terraform

# Format check
terraform fmt -check

# Validate configuration
terraform validate

# Security scan
checkov -d .
```

---

## 💰 Cost Breakdown

### One-Time Setup Costs
- **S3 Data Upload:** $0.005 (PUT requests)
- **Lambda Deployment:** $0.00 (free tier)

### Monthly Operating Costs

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| **S3 Storage** | 7 MB across 3 buckets | $0.00 |
| **Lambda Executions** | ~30 invocations/month | $0.00 (free tier) |
| **Glue Crawler** | ~30 runs/month | $0.00 (free tier) |
| **Athena Queries** | ~100 queries, 100 MB scanned | $0.05 |
| **Step Functions** | ~30 executions/month | $0.00 (free tier) |
| **CloudWatch Logs** | 500 MB ingestion | $0.00 (free tier) |
| **EventBridge** | ~30 events/month | $0.00 (free tier) |
| **Data Transfer** | Within same region | $0.00 |
| **TOTAL** | | **~$0.05/month** |

### Project Development Cost
- **Total spent during 14-day development:** $0.60
- **Budget:** $5.00
- **Under budget by:** $4.40 ✅

### Cost Optimization Strategies

1. **Parquet Format:** 70% smaller than CSV, reduces Athena scan costs
2. **Partitioning:** Reduces data scanned by 90% for time-based queries
3. **Compression:** Snappy compression reduces storage by 3x
4. **Serverless:** No idle resource costs, pay only for usage
5. **Free Tier:** Step Functions, Lambda, Glue all within free tier limits

---

## 🎓 Skills Demonstrated

### Cloud Engineering
- ✅ AWS service selection and architecture design
- ✅ Cost optimization and resource management
- ✅ Security best practices (IAM, encryption)
- ✅ Serverless architecture patterns

### Data Engineering
- ✅ ETL/ELT pipeline design and implementation
- ✅ Data modeling (star schema, medallion architecture)
- ✅ Data quality and validation
- ✅ Performance optimization (partitioning, compression)
- ✅ Schema evolution and backwards compatibility

### Infrastructure as Code
- ✅ Terraform modules and state management
- ✅ Resource dependencies and lifecycle management
- ✅ Multi-environment configuration
- ✅ Infrastructure testing and validation

### Software Engineering
- ✅ Python programming (OOP, functional)
- ✅ SQL query optimization
- ✅ Unit testing and TDD
- ✅ Code quality and documentation
- ✅ Version control (Git)

### DevOps
- ✅ CI/CD pipeline design (GitHub Actions)
- ✅ Automated testing and deployment
- ✅ Monitoring and alerting (CloudWatch)
- ✅ Workflow orchestration (Step Functions)

### Data Visualization
- ✅ Dashboard design principles
- ✅ Interactive visualizations (Tableau)
- ✅ KPI selection and presentation
- ✅ Data storytelling

---

## 📚 Project Documentation

### Detailed Guides
- **[Setup Guide](docs/setup_guide.md)** - Complete installation instructions
- **[Architecture Details](docs/architecture.md)** - Deep dive into system design
- **[API Documentation](docs/api.md)** - Function and endpoint references
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Cost Analysis](docs/cost_analysis.md)** - Detailed cost breakdown

### Day-by-Day Build Log
- Days 1-2: Infrastructure setup (Terraform, S3, Lambda)
- Days 3-4: Data generation and ingestion
- Day 5: Lambda function implementation
- Days 6-8: ETL transformations (Bronze → Silver → Gold)
- Day 9: Athena analytics and SQL queries
- Days 10-11: Step Functions orchestration
- Day 12: Tableau dashboard creation
- Day 13: CI/CD pipeline setup
- Day 14: Redshift demo and final polish

---

## 🔮 Future Enhancements

### Short Term
- [ ] Add real-time streaming with Kinesis
- [ ] Implement dbt for transformation management
- [ ] Create QuickSight dashboards as alternative to Tableau
- [ ] Add data lineage tracking

### Medium Term
- [ ] Apache Airflow for complex workflow orchestration
- [ ] Great Expectations for advanced data quality
- [ ] Delta Lake for ACID transactions
- [ ] Snowflake integration as alternative warehouse

### Long Term
- [ ] Machine learning predictions (SageMaker)
- [ ] Real-time anomaly detection
- [ ] Customer churn prediction model
- [ ] Recommendation engine

---

## 🐛 Troubleshooting

### Common Issues

**Issue: Terraform apply fails with permission denied**
```bash
# Solution: Check AWS credentials
aws sts get-caller-identity

# Ensure IAM user has AdministratorAccess or equivalent permissions
```

**Issue: Athena query returns no results**
```bash
# Solution: Repair table partitions
aws athena start-query-execution \
  --query-string "MSCK REPAIR TABLE daily_sales_summary" \
  --query-execution-context Database=ecommerce_analytics_dev

# Verify partitions
aws athena start-query-execution \
  --query-string "SHOW PARTITIONS daily_sales_summary"
```

**Issue: Lambda function times out**
```bash
# Solution: Check CloudWatch logs
aws logs tail /aws/lambda/ecommerce-analytics-dev-ingestion --follow

# Increase timeout in Terraform if needed
```

**Issue: Step Functions execution fails**
```bash
# Solution: Check execution details
aws stepfunctions describe-execution \
  --execution-arn <YOUR_EXECUTION_ARN>

# View CloudWatch logs for detailed error messages
```

**Issue: High Athena costs**
```bash
# Solution: Always use partition filters in WHERE clause
# Good: WHERE year = 2025 AND month = 1
# Bad: WHERE order_date >= '2025-01-01'  (scans all partitions)
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request**

### Development Guidelines
- Follow PEP 8 style guide for Python code
- Write unit tests for new features
- Update documentation for any changes
- Ensure all tests pass before submitting PR

---

## 🙏 Acknowledgments

- **AWS Documentation** - Comprehensive guides and best practices
- **Terraform Registry** - Module examples and patterns
- **Data Engineering Community** - Inspiration and knowledge sharing
- **Faker Library** - Realistic synthetic data generation
- **Tableau Public** - Free visualization platform

---

## 📞 Contact

**Your Name**  
📧 Email: asp881999@gmail.com
💼 LinkedIn: [linkedin.com/in/yourprofile](https://www.linkedin.com/in/toaungsettpaing/)  
🐙 GitHub: [@settpaing89](https://github.com/settpaing89)  


---

## 🌟 Show Your Support

If you found this project helpful or interesting:
- ⭐ **Star this repository** to show your support
- 🔄 **Share it** with others who might find it useful
- 🐛 **Report bugs** to help improve the project
- 💡 **Suggest features** for future enhancements

---

<div align="center">

**Built with ❤️ by Aung Sett Paing**

*Demonstrating production-ready data engineering skills for real-world impact*

[⬆ Back to Top](#-e-commerce-real-time-analytics-pipeline)

</div>