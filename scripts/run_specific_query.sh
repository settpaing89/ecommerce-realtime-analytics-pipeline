#!/bin/bash

source config/aws_resources.sh

QUERY_NAME=$1

if [ -z "$QUERY_NAME" ]; then
    echo "Available queries:"
    echo "  1. revenue_trend"
    echo "  2. monthly_growth"
    echo "  3. customer_segments"
    echo "  4. top_customers"
    echo "  5. customer_retention"
    echo "  6. top_products"
    echo "  7. category_performance"
    echo "  8. slow_products"
    echo "  9. conversion_funnel"
    echo " 10. executive_summary"
    echo ""
    echo "Usage: ./scripts/run_specific_query.sh <query_name>"
    exit 1
fi

# Extract specific query from analytics_queries.sql
case $QUERY_NAME in
    revenue_trend)
        QUERY=$(sed -n '/-- 1. Revenue Trend/,/-- 2. Month-over-Month/p' src/warehouse/analytics_queries.sql | sed '1d;$d')
        ;;
    monthly_growth)
        QUERY=$(sed -n '/-- 2. Month-over-Month/,/-- ============================================/p' src/warehouse/analytics_queries.sql | grep -v "^--" | sed '/^$/d')
        ;;
    customer_segments)
        QUERY=$(sed -n '/-- 3. Customer Segmentation/,/-- 4. Top 100 Customers/p' src/warehouse/analytics_queries.sql | sed '1d;$d')
        ;;
    top_customers)
        QUERY=$(sed -n '/-- 4. Top 100 Customers/,/-- 5. Customer Retention/p' src/warehouse/analytics_queries.sql | sed '1d;$d')
        ;;
    customer_retention)
        QUERY=$(sed -n '/-- 5. Customer Retention/,/-- ============================================/p' src/warehouse/analytics_queries.sql | grep -v "^--" | sed '/^$/d')
        ;;
    top_products)
        QUERY=$(sed -n '/-- 6. Top 20 Products/,/-- 7. Product Performance/p' src/warehouse/analytics_queries.sql | sed '1d;$d')
        ;;
    category_performance)
        QUERY=$(sed -n '/-- 7. Product Performance/,/-- 8. Slow-Moving/p' src/warehouse/analytics_queries.sql | sed '1d;$d')
        ;;
    slow_products)
        QUERY=$(sed -n '/-- 8. Slow-Moving/,/-- ============================================/p' src/warehouse/analytics_queries.sql | grep -v "^--" | sed '/^$/d')
        ;;
    conversion_funnel)
        QUERY=$(sed -n '/-- 9. Conversion Funnel/,/-- ============================================/p' src/warehouse/analytics_queries.sql | grep -v "^--" | sed '/^$/d')
        ;;
    executive_summary)
        QUERY=$(sed -n '/-- 10. Key Business Metrics/,/EOF/p' src/warehouse/analytics_queries.sql | sed '1d;$d')
        ;;
    *)
        echo "Unknown query: $QUERY_NAME"
        exit 1
        ;;
esac

echo "Running $QUERY_NAME query..."
echo "================================"

# Execute query
EXECUTION_ID=$(aws athena start-query-execution \
    --query-string "$QUERY" \
    --query-execution-context Database=$GLUE_DATABASE \
    --result-configuration OutputLocation=s3://$GOLD_BUCKET/athena-results/ \
    --work-group $ATHENA_WORKGROUP \
    --query 'QueryExecutionId' \
    --output text)

echo "Execution ID: $EXECUTION_ID"
echo "Waiting for results..."

# Wait for completion
while true; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id $EXECUTION_ID \
        --query 'QueryExecution.Status.State' \
        --output text)
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "✅ Query completed successfully!"
        echo ""
        
        # Display results
        aws athena get-query-results \
            --query-execution-id $EXECUTION_ID \
            --output table
        
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "❌ Query failed"
        aws athena get-query-execution \
            --query-execution-id $EXECUTION_ID \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text
        exit 1
    fi
    
    sleep 2
done
