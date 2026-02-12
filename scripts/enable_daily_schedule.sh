#!/bin/bash

# Enable daily pipeline execution

source config/aws_resources.sh

RULE_NAME=$(cd terraform && terraform output -raw eventbridge_rule_name)

echo "Enabling daily schedule..."
echo "Rule: $RULE_NAME"
echo ""

aws events enable-rule --name $RULE_NAME

if [ $? -eq 0 ]; then
    echo "✅ Daily schedule enabled!"
    echo ""
    echo "Pipeline will run daily at 2 AM UTC"
    echo ""
    echo "To disable:"
    echo "  aws events disable-rule --name $RULE_NAME"
else
    echo "❌ Failed to enable schedule"
fi
