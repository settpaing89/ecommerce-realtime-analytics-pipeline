# Create a cost check script that works on both macOS and Linux
#!/bin/bash

source config/aws_resources.sh

echo "========================================"
echo "AWS Cost Check"
echo "========================================"
echo ""

# Check current month costs
echo "📊 Total Spending This Month:"
aws ce get-cost-and-usage \
    --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
    --output text | awk '{printf "$%.4f\n", $1}'

echo ""
echo "💰 Spending by Service:"
aws ce get-cost-and-usage \
    --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --group-by Type=SERVICE \
    --query 'ResultsByTime[0].Groups[].[Keys[0],Metrics.BlendedCost.Amount]' \
    --output text | awk '{printf "%-30s $%.4f\n", $1, $2}' | grep -v "0.0000$" || echo "No charges yet"

echo ""
echo "📦 S3 Bucket Info:"
echo "Bronze Bucket: $BRONZE_BUCKET"

# List objects
OBJECT_COUNT=$(aws s3 ls s3://$BRONZE_BUCKET/ --recursive | wc -l | tr -d ' ')
echo "Objects: $OBJECT_COUNT"

# Get total size
TOTAL_SIZE=$(aws s3 ls s3://$BRONZE_BUCKET/ --recursive --summarize | grep "Total Size" | awk '{print $3}')
if [ ! -z "$TOTAL_SIZE" ]; then
    SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)
    echo "Total Size: ${SIZE_MB} MB"
    
    # Calculate cost (S3 Standard: $0.023/GB)
    SIZE_GB=$(echo "scale=4; $TOTAL_SIZE / 1024 / 1024 / 1024" | bc)
    STORAGE_COST=$(echo "scale=4; $SIZE_GB * 0.023" | bc)
    echo "Estimated Storage Cost: \$$STORAGE_COST/month"
else
    echo "Total Size: 0 MB (bucket empty or no data yet)"
fi

echo ""
echo "========================================"
