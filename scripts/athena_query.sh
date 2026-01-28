#!/bin/bash

# Athena Query Helper Script

source config/aws_resources.sh

QUERY=$1
OUTPUT_LOCATION="s3://$GOLD_BUCKET/athena-results/"

if [ -z "$QUERY" ]; then
    echo "Usage: ./scripts/athena_query.sh 'SELECT * FROM orders LIMIT 10'"
    exit 1
fi

echo "Running query: $QUERY"
echo ""

# Start query execution
EXECUTION_ID=$(aws athena start-query-execution \
    --query-string "$QUERY" \
    --query-execution-context Database=$GLUE_DATABASE \
    --result-configuration OutputLocation=$OUTPUT_LOCATION \
    --work-group $ATHENA_WORKGROUP \
    --query 'QueryExecutionId' \
    --output text)

echo "Query execution ID: $EXECUTION_ID"
echo "Waiting for results..."

# Wait for query to complete
while true; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id $EXECUTION_ID \
        --query 'QueryExecution.Status.State' \
        --output text)
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "✅ Query succeeded!"
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "❌ Query failed!"
        aws athena get-query-execution --query-execution-id $EXECUTION_ID
        exit 1
    fi
    
    sleep 2
done

# Get results
echo ""
echo "Results:"
aws athena get-query-results \
    --query-execution-id $EXECUTION_ID \
    --output table

# Show cost (approximate)
DATA_SCANNED=$(aws athena get-query-execution \
    --query-execution-id $EXECUTION_ID \
    --query 'QueryExecution.Statistics.DataScannedInBytes' \
    --output text)

COST=$(echo "scale=6; $DATA_SCANNED / 1099511627776 * 5" | bc)
echo ""
echo "Data scanned: $(numfmt --to=iec-i --suffix=B $DATA_SCANNED)"
echo "Approximate cost: \$$COST"
