#!/bin/bash

# Test Lambda function with different scenarios

source config/aws_resources.sh

echo "🧪 Testing Lambda Function"
echo "=========================="

# Test 1: Valid orders
echo "Test 1: Valid orders..."
aws lambda invoke \
  --function-name $LAMBDA_FUNCTION \
  --payload '{
    "data_type": "order",
    "records": [
      {
        "order_id": "ORD-TEST-001",
        "customer_id": "CUST-000001",
        "product_id": "PROD-0001",
        "order_date": "2025-01-27T10:00:00",
        "quantity": 1,
        "total_amount": 49.99,
        "status": "pending"
      }
    ]
  }' \
  /tmp/response1.json --cli-binary-format raw-in-base64-out

echo "Response:"
cat /tmp/response1.json | jq .
echo ""

# Test 2: Invalid order (missing required field)
echo "Test 2: Invalid order..."
aws lambda invoke \
  --function-name $LAMBDA_FUNCTION \
  --payload '{
    "data_type": "order",
    "records": [
      {
        "customer_id": "CUST-000001",
        "total_amount": 49.99
      }
    ]
  }' \
  /tmp/response2.json --cli-binary-format raw-in-base64-out

echo "Response:"
cat /tmp/response2.json | jq .
echo ""

# Test 3: Customer data
echo "Test 3: Customer data..."
aws lambda invoke \
  --function-name $LAMBDA_FUNCTION \
  --payload '{
    "data_type": "customer",
    "records": [
      {
        "customer_id": "CUST-TEST-001",
        "email": "test@example.com",
        "first_name": "Test",
        "last_name": "User",
        "phone": "555-0123",
        "is_active": true
      }
    ]
  }' \
  /tmp/response3.json --cli-binary-format raw-in-base64-out

echo "Response:"
cat /tmp/response3.json | jq .

echo ""
echo "=========================="
echo "✅ Tests complete!"
