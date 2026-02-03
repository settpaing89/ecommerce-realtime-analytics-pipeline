#!/bin/bash

source config/aws_resources.sh

echo "========================================"
echo "Athena Setup Verification"
echo "========================================"
echo ""

# Check database
echo "1. Checking Glue Database..."
aws glue get-database --name $GLUE_DATABASE &>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Database '$GLUE_DATABASE' exists"
else
    echo "   ❌ Database '$GLUE_DATABASE' not found"
fi

# Check tables
echo ""
echo "2. Checking Tables..."
tables=("daily_sales_summary" "customer_lifetime_value" "product_performance" "conversion_funnel")

for table in "${tables[@]}"; do
    aws glue get-table --database-name $GLUE_DATABASE --name $table &>/dev/null
    if [ $? -eq 0 ]; then
        echo "   ✅ Table '$table' exists"
    else
        echo "   ❌ Table '$table' not found"
    fi
done

# Check S3 data
echo ""
echo "3. Checking Gold Layer Data..."
for table in "${tables[@]}"; do
    count=$(aws s3 ls s3://$GOLD_BUCKET/$table/ --recursive | wc -l)
    if [ $count -gt 0 ]; then
        echo "   ✅ $table: $count files"
    else
        echo "   ⚠️  $table: No data files"
    fi
done

# Run test query
echo ""
echo "4. Running Test Query..."
EXECUTION_ID=$(aws athena start-query-execution \
    --query-string "SELECT COUNT(*) as row_count FROM daily_sales_summary" \
    --query-execution-context Database=$GLUE_DATABASE \
    --result-configuration OutputLocation=s3://$GOLD_BUCKET/athena-results/ \
    --work-group $ATHENA_WORKGROUP \
    --query 'QueryExecutionId' \
    --output text)

sleep 5

STATUS=$(aws athena get-query-execution \
    --query-execution-id $EXECUTION_ID \
    --query 'QueryExecution.Status.State' \
    --output text)

if [ "$STATUS" = "SUCCEEDED" ]; then
    echo "   ✅ Test query succeeded"
else
    echo "   ❌ Test query failed: $STATUS"
fi

echo ""
echo "========================================"
echo "Verification Complete"
echo "========================================"
