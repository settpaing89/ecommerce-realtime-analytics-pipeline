#!/bin/bash

source config/aws_resources.sh

echo "========================================"
echo "Testing Athena Table Data"
echo "========================================"
echo ""

# Function to run a simple count query
test_table() {
    local table_name=$1
    
    echo "Testing table: $table_name"
    
    QUERY="SELECT COUNT(*) as row_count FROM $table_name"
    
    EXECUTION_ID=$(aws athena start-query-execution \
        --query-string "$QUERY" \
        --query-execution-context Database=$GLUE_DATABASE \
        --result-configuration OutputLocation=s3://$GOLD_BUCKET/athena-results/ \
        --work-group $ATHENA_WORKGROUP \
        --query 'QueryExecutionId' \
        --output text)
    
    # Wait for completion
    sleep 3
    
    STATUS=$(aws athena get-query-execution \
        --query-execution-id $EXECUTION_ID \
        --query 'QueryExecution.Status.State' \
        --output text)
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        # Get the count
        COUNT=$(aws athena get-query-results \
            --query-execution-id $EXECUTION_ID \
            --query 'ResultSet.Rows[1].Data[0].VarCharValue' \
            --output text)
        
        if [ "$COUNT" = "0" ] || [ "$COUNT" = "None" ]; then
            echo "  ⚠️  Table exists but has NO DATA (0 rows)"
        else
            echo "  ✅ Table has $COUNT rows"
        fi
    elif [ "$STATUS" = "FAILED" ]; then
        ERROR=$(aws athena get-query-execution \
            --query-execution-id $EXECUTION_ID \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text)
        echo "  ❌ Query failed: $ERROR"
    else
        echo "  ⏱️  Query status: $STATUS"
    fi
    
    echo ""
}

# Test all tables
test_table "daily_sales_summary"
test_table "customer_lifetime_value"
test_table "product_performance"
test_table "conversion_funnel"

echo "========================================"
echo "Test Complete"
echo "========================================"
echo ""
echo "If tables show 0 rows, you need to:"
echo "1. Run the transformation scripts:"
echo "   python src/processing/transform_bronze_to_silver.py"
echo "   python src/processing/transform_silver_to_gold.py"
echo ""
echo "2. Repair partitions:"
echo "   ./create_athena_tables_fixed.sh"
echo "   (This will repair partitions automatically)"