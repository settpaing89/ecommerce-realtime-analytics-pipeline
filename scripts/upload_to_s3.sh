# Create upload script
#!/bin/bash

# Upload to S3 Script
# Uploads data with proper partitioning

set -e  # Exit on error

# Load environment variables
source config/aws_resources.sh

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================"
echo "Uploading Data to S3"
echo "========================================"
echo ""

# Check if data exists
if [ ! -d "data/bronze" ]; then
    echo "❌ Error: data/bronze/ directory not found"
    echo "Run: python src/data_generation/generate_data.py first"
    exit 1
fi

# Get current date for partitioning
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)

echo -e "${BLUE}Target Bucket:${NC} $BRONZE_BUCKET"
echo -e "${BLUE}Partition:${NC} year=$YEAR/month=$MONTH/day=$DAY"
echo ""

# Upload each dataset
echo "Uploading datasets..."

# Customers
echo -e "${GREEN}1/4${NC} Uploading customers..."
aws s3 cp data/bronze/customers.parquet \
    s3://$BRONZE_BUCKET/customers/year=$YEAR/month=$MONTH/day=$DAY/customers.parquet \
    --metadata "uploaded-by=data-pipeline,dataset=customers"

# Products
echo -e "${GREEN}2/4${NC} Uploading products..."
aws s3 cp data/bronze/products.parquet \
    s3://$BRONZE_BUCKET/products/year=$YEAR/month=$MONTH/day=$DAY/products.parquet \
    --metadata "uploaded-by=data-pipeline,dataset=products"

# Orders
echo -e "${GREEN}3/4${NC} Uploading orders..."
aws s3 cp data/bronze/orders.parquet \
    s3://$BRONZE_BUCKET/orders/year=$YEAR/month=$MONTH/day=$DAY/orders.parquet \
    --metadata "uploaded-by=data-pipeline,dataset=orders"

# Events
echo -e "${GREEN}4/4${NC} Uploading events..."
aws s3 cp data/bronze/events.parquet \
    s3://$BRONZE_BUCKET/events/year=$YEAR/month=$MONTH/day=$DAY/events.parquet \
    --metadata "uploaded-by=data-pipeline,dataset=events"

echo ""
echo "========================================"
echo "✅ Upload Complete!"
echo "========================================"
echo ""

# Verify upload
echo "Verifying upload..."
aws s3 ls s3://$BRONZE_BUCKET/ --recursive --human-readable --summarize | tail -5

echo ""
echo "Next steps:"
echo "1. Run Glue Crawler: aws glue start-crawler --name $GLUE_CRAWLER"
echo "2. Wait 2-3 minutes for crawler to finish"
echo "3. Query with Athena"
