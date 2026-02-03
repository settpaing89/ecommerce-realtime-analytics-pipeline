#!/bin/bash

# Script to create Athena tables one statement at a time

source config/aws_resources.sh

echo "========================================"
echo "Creating Athena Tables"
echo "========================================"
echo ""

# Function to execute a single query
execute_query() {
    local query="$1"
    local description="$2"
    
    echo "Creating: $description"
    
    EXECUTION_ID=$(aws athena start-query-execution \
        --query-string "$query" \
        --query-execution-context Database=$GLUE_DATABASE \
        --result-configuration OutputLocation=s3://$GOLD_BUCKET/athena-results/ \
        --work-group $ATHENA_WORKGROUP \
        --query 'QueryExecutionId' \
        --output text)
    
    # Wait for completion
    while true; do
        STATUS=$(aws athena get-query-execution \
            --query-execution-id $EXECUTION_ID \
            --query 'QueryExecution.Status.State' \
            --output text)
        
        if [ "$STATUS" = "SUCCEEDED" ]; then
            echo "  ✅ Success"
            break
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
            echo "  ❌ Failed"
            aws athena get-query-execution \
                --query-execution-id $EXECUTION_ID \
                --query 'QueryExecution.Status.StateChangeReason' \
                --output text
            return 1
        fi
        sleep 1
    done
    
    echo ""
}

# 1. Create Daily Sales Summary Table
execute_query "
CREATE EXTERNAL TABLE IF NOT EXISTS daily_sales_summary (
    order_date DATE,
    total_orders BIGINT,
    unique_customers BIGINT,
    total_revenue DOUBLE,
    avg_order_value DOUBLE,
    total_units_sold BIGINT,
    avg_units_per_order DOUBLE
)
PARTITIONED BY (
    year INT,
    month INT
)
STORED AS PARQUET
LOCATION 's3://$GOLD_BUCKET/daily_sales_summary/'
" "daily_sales_summary table"

# 2. Create Customer Lifetime Value Table
execute_query "
CREATE EXTERNAL TABLE IF NOT EXISTS customer_lifetime_value (
    customer_id STRING,
    total_orders BIGINT,
    lifetime_value DOUBLE,
    first_order_date TIMESTAMP,
    last_order_date TIMESTAMP,
    avg_order_value DOUBLE,
    days_as_customer INT,
    days_since_last_order INT,
    segment STRING
)
PARTITIONED BY (
    year INT,
    month INT
)
STORED AS PARQUET
LOCATION 's3://$GOLD_BUCKET/customer_lifetime_value/'
" "customer_lifetime_value table"

# 3. Create Product Performance Table
execute_query "
CREATE EXTERNAL TABLE IF NOT EXISTS product_performance (
    product_id STRING,
    times_ordered BIGINT,
    units_sold BIGINT,
    total_revenue DOUBLE,
    product_name STRING,
    category STRING,
    current_price DOUBLE,
    cost DOUBLE,
    total_profit DOUBLE,
    profit_margin DOUBLE,
    avg_revenue_per_order DOUBLE,
    revenue_rank DOUBLE
)
PARTITIONED BY (
    year INT,
    month INT
)
STORED AS PARQUET
LOCATION 's3://$GOLD_BUCKET/product_performance/'
" "product_performance table"

# 4. Create Conversion Funnel Table
execute_query "
CREATE EXTERNAL TABLE IF NOT EXISTS conversion_funnel (
    event_type STRING,
    total_events BIGINT,
    unique_sessions BIGINT,
    session_conversion_rate DOUBLE,
    stage_order INT
)
PARTITIONED BY (
    year INT,
    month INT
)
STORED AS PARQUET
LOCATION 's3://$GOLD_BUCKET/conversion_funnel/'
" "conversion_funnel table"

# 5. Repair partitions for daily_sales_summary
execute_query "
MSCK REPAIR TABLE daily_sales_summary
" "Repair partitions: daily_sales_summary"

# 6. Repair partitions for customer_lifetime_value
execute_query "
MSCK REPAIR TABLE customer_lifetime_value
" "Repair partitions: customer_lifetime_value"

# 7. Repair partitions for product_performance
execute_query "
MSCK REPAIR TABLE product_performance
" "Repair partitions: product_performance"

# 8. Repair partitions for conversion_funnel
execute_query "
MSCK REPAIR TABLE conversion_funnel
" "Repair partitions: conversion_funnel"

echo "========================================"
echo "✅ All Athena Tables Created!"
echo "========================================"
echo ""
echo "You can now view your tables in:"
echo "  AWS Console > Athena > Query Editor"
echo "  Database: $GLUE_DATABASE"
echo ""
echo "Available tables:"
echo "  - daily_sales_summary"
echo "  - customer_lifetime_value"
echo "  - product_performance"
echo "  - conversion_funnel"