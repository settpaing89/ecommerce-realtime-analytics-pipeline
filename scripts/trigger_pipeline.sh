#!/bin/bash

# Trigger Step Functions pipeline

source config/aws_resources.sh

# Get state machine ARN
STATE_MACHINE_ARN=$(cd terraform && terraform output -raw step_functions_state_machine_arn)

if [ -z "$STATE_MACHINE_ARN" ]; then
    echo "❌ Could not get state machine ARN"
    exit 1
fi

# Create execution name
EXECUTION_NAME="manual-run-$(date +%Y%m%d-%H%M%S)"

echo "========================================"
echo "Triggering Pipeline"
echo "========================================"
echo ""
echo "State Machine: $STATE_MACHINE_ARN"
echo "Execution Name: $EXECUTION_NAME"
echo ""

# Start execution
EXECUTION_ARN=$(aws stepfunctions start-execution \
    --state-machine-arn $STATE_MACHINE_ARN \
    --name $EXECUTION_NAME \
    --input '{}' \
    --query 'executionArn' \
    --output text)

if [ -z "$EXECUTION_ARN" ]; then
    echo "❌ Failed to start execution"
    exit 1
fi

echo "✅ Execution started!"
echo "Execution ARN: $EXECUTION_ARN"
echo ""
echo "Monitor at:"
echo "  https://console.aws.amazon.com/states/home?region=us-east-1#/executions/details/$EXECUTION_ARN"
echo ""

# Monitor execution
echo "Monitoring status..."
echo ""

while true; do
    STATUS=$(aws stepfunctions describe-execution \
        --execution-arn $EXECUTION_ARN \
        --query 'status' \
        --output text)
    
    echo -ne "Status: $STATUS\r"
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo ""
        echo "✅ Pipeline completed successfully!"
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "TIMED_OUT" ] || [ "$STATUS" = "ABORTED" ]; then
        echo ""
        echo "❌ Pipeline $STATUS"
        
        # Get error details
        aws stepfunctions describe-execution \
            --execution-arn $EXECUTION_ARN \
            --query '{error: error, cause: cause}' \
            --output json
        
        exit 1
    fi
    
    sleep 5
done

echo ""
echo "View logs in CloudWatch:"
echo "  Log Group: /aws/vendedlogs/states/ecommerce-analytics-dev-pipeline"
