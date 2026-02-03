#!/bin/bash

echo "========================================"
echo "Running Full Analytics Suite"
echo "========================================"
echo ""

queries=(
    "executive_summary"
    "revenue_trend"
    "customer_segments"
    "top_products"
    "conversion_funnel"
)

for query in "${queries[@]}"; do
    echo ""
    echo "Running: $query"
    echo "----------------------------------------"
    ./scripts/run_specific_query.sh $query
    echo ""
    sleep 2
done

echo "========================================"
echo "✅ All Analytics Complete"
echo "========================================"
