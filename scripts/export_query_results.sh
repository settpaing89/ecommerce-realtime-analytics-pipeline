#!/bin/bash

source config/aws_resources.sh

EXECUTION_ID=$1
OUTPUT_FILE=$2

if [ -z "$EXECUTION_ID" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: ./scripts/export_query_results.sh <execution_id> <output_file.csv>"
    exit 1
fi

echo "Exporting results from execution: $EXECUTION_ID"

# Get results and convert to CSV
aws athena get-query-results \
    --query-execution-id $EXECUTION_ID \
    --output json | \
    jq -r '.ResultSet.Rows[] | .Data | map(.VarCharValue // "") | @csv' > $OUTPUT_FILE

echo "✅ Results exported to: $OUTPUT_FILE"
