#!/bin/bash

# Export Athena query results for dashboard creation

source config/aws_resources.sh

echo "========================================"
echo "Exporting Data for Dashboards"
echo "========================================"
echo ""

# Create export directory
mkdir -p dashboards/data

# Function to run query and export
export_query() {
    local query_name=$1
    local query=$2
    local output_file=$3
    
    echo "Exporting: $query_name"
    
    # Run query
    EXECUTION_ID=$(aws athena start-query-execution \
        --query-string "$query" \
        --query-execution-context Database=$GLUE_DATABASE \
        --result-configuration OutputLocation=s3://$GOLD_BUCKET/exports/ \
        --work-group $ATHENA_WORKGROUP \
        --query 'QueryExecutionId' \
        --output text)
    
    # Wait for completion
    sleep 10
    
    STATUS=$(aws athena get-query-execution \
        --query-execution-id $EXECUTION_ID \
        --query 'QueryExecution.Status.State' \
        --output text)
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        # Get results as CSV directly from S3 (Athena saves results as CSV)
        
        # Get the actual output location from Athena
        # This handles cases where Workgroup settings override client-side OutputLocation
        OUTPUT_LOCATION=$(aws athena get-query-execution \
            --query-execution-id $EXECUTION_ID \
            --query 'QueryExecution.ResultConfiguration.OutputLocation' \
            --output text)
            
        # Download the file using the exact S3 path returned by Athena
        aws s3 cp "$OUTPUT_LOCATION" "dashboards/data/${output_file}"
        
        echo "  ✅ Exported to dashboards/data/${output_file}"
    else
        echo "  ❌ Query failed: $STATUS"
    fi
    
    echo ""
}

# Export daily sales
export_query "Daily Sales" \
"SELECT 
    order_date,
    total_orders,
    unique_customers,
    total_revenue,
    avg_order_value,
    total_units_sold
FROM daily_sales_summary
ORDER BY order_date DESC
LIMIT 60" \
"daily_sales.csv"

# Export customer segments
export_query "Customer Segments" \
"SELECT 
    segment,
    COUNT(*) as customer_count,
    ROUND(AVG(lifetime_value), 2) as avg_ltv,
    ROUND(AVG(total_orders), 2) as avg_orders
FROM customer_lifetime_value
GROUP BY segment
ORDER BY avg_ltv DESC" \
"customer_segments.csv"

# Export top products
export_query "Top Products" \
"SELECT 
    product_name,
    category,
    total_revenue,
    units_sold,
    profit_margin
FROM product_performance
ORDER BY total_revenue DESC
LIMIT 20" \
"top_products.csv"

# Export category performance
export_query "Category Performance" \
"SELECT 
    category,
    COUNT(DISTINCT product_id) as num_products,
    SUM(total_revenue) as category_revenue,
    SUM(units_sold) as units_sold
FROM product_performance
GROUP BY category
ORDER BY category_revenue DESC" \
"category_performance.csv"

echo "========================================"
echo "✅ Export Complete!"
echo "========================================"
echo ""
echo "Data files in: dashboards/data/"
echo ""
ls -lh dashboards/data/
