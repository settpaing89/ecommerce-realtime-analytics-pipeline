#!/bin/bash
source config/aws_resources.sh

QUERY_FILE=$1

if [ -z "$QUERY_FILE" ]; then
    echo "Usage: ./scripts/run_athena_query.sh <query_file.sql>"
    exit 1
fi

# Read query
QUERY=$(cat $QUERY_FILE)

# Run in Athena
EXECUTION_ID=$(aws athena start-query-execution \
    --query-string "$QUERY" \
    --query-execution-context Database=$GLUE_DATABASE \
    --result-configuration OutputLocation=s3://$GOLD_BUCKET/athena-results/ \
    --work-group $ATHENA_WORKGROUP \
    --query 'QueryExecutionId' \
    --output text)

echo "Query execution ID: $EXECUTION_ID"
echo "Waiting for results..."

# Wait for completion
while true; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id $EXECUTION_ID \
        --query 'QueryExecution.Status.State' \
        --output text)
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "✅ Query succeeded!"
        
        # Get results
        aws athena get-query-results \
            --query-execution-id $EXECUTION_ID \
            --output table
        
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "❌ Query failed or was cancelled"
        
        # Get error message
        aws athena get-query-execution \
            --query-execution-id $EXECUTION_ID \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text
        
        exit 1
    fi
    
    echo "Status: $STATUS"
    sleep 2
done