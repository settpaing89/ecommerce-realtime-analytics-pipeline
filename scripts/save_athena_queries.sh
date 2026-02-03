#!/bin/bash

source config/aws_resources.sh

echo "Creating saved queries in Athena..."

# This creates named queries in Athena for easy reuse
queries=(
    "Revenue Trend:SELECT order_date, total_revenue, total_orders FROM daily_sales_summary WHERE order_date >= CURRENT_DATE - INTERVAL '30' DAY ORDER BY order_date DESC;"
    "Top Customers:SELECT customer_id, lifetime_value, total_orders, segment FROM customer_lifetime_value ORDER BY lifetime_value DESC LIMIT 100;"
    "Top Products:SELECT product_name, category, total_revenue, units_sold FROM product_performance ORDER BY total_revenue DESC LIMIT 20;"
)

for query_def in "${queries[@]}"; do
    IFS=: read -r name query <<< "$query_def"
    
    aws athena create-named-query \
        --name "$name" \
        --database $GLUE_DATABASE \
        --query-string "$query" \
        --work-group $ATHENA_WORKGROUP
    
    echo "✅ Saved: $name"
done

echo ""
echo "Saved queries are now available in AWS Console > Athena > Saved queries"
