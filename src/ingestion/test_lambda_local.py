"""
Local testing script for Lambda function
Tests validation and enrichment WITHOUT AWS calls
"""

import json
import os
import sys
from unittest.mock import patch, MagicMock

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Set environment variables for testing
os.environ['BRONZE_BUCKET'] = 'test-bucket'
os.environ['ENVIRONMENT'] = 'dev'

# Import Lambda function
from lambda_function import lambda_handler, enrich_records, validate_records

class MockContext:
    function_name = 'test-function'
    memory_limit_in_mb = 256
    invoked_function_arn = 'arn:aws:lambda:us-east-1:123456789012:function:test'
    aws_request_id = 'test-request-id'

def test_validation():
    """Test data validation (no AWS)"""
    print("Testing data validation...")
    
    # Test valid order
    records = [{
        'order_id': 'ORD-001',
        'customer_id': 'CUST-001',
        'product_id': 'PROD-001',
        'total_amount': 100.0,
        'quantity': 1,
        'status': 'pending'
    }]
    
    valid, invalid = validate_records(records, 'order')
    assert len(valid) == 1
    assert len(invalid) == 0
    print("✓ Valid order passed validation")
    
    # Test invalid order (missing required field)
    records = [{
        'customer_id': 'CUST-001',
        'total_amount': 100.0
    }]
    
    valid, invalid = validate_records(records, 'order')
    assert len(valid) == 0
    assert len(invalid) == 1
    print("✓ Invalid order rejected")
    
    # Test business rule (negative amount)
    records = [{
        'order_id': 'ORD-001',
        'customer_id': 'CUST-001',
        'product_id': 'PROD-001',
        'total_amount': -100.0,  # Invalid!
        'quantity': 1,
        'status': 'pending'
    }]
    
    valid, invalid = validate_records(records, 'order')
    assert len(invalid) == 1
    print("✓ Business rule validation works")
    
    print("All validation tests passed!\n")

def test_enrichment():
    """Test data enrichment (no AWS)"""
    print("Testing data enrichment...")
    
    records = [{
        'order_id': 'ORD-001',
        'order_date': '2025-01-27T10:00:00'
    }]
    
    enriched = enrich_records(records, 'order')
    
    # Check metadata fields added
    assert '_ingestion_timestamp' in enriched[0]
    assert '_source' in enriched[0]
    assert '_data_type' in enriched[0]
    assert '_environment' in enriched[0]
    assert enriched[0]['_data_type'] == 'order'
    
    # Check date parsing worked
    assert '_order_year' in enriched[0]
    assert '_order_month' in enriched[0]
    assert enriched[0]['_order_year'] == 2025
    assert enriched[0]['_order_month'] == 1
    
    print("✓ Records enriched successfully")
    print(f"  Metadata fields: {[k for k in enriched[0].keys() if k.startswith('_')]}")
    print()

def test_different_data_types():
    """Test validation for different data types (no AWS)"""
    print("Testing different data types...")
    
    # Customer
    records = [{
        'customer_id': 'CUST-001',
        'email': 'test@example.com',
        'first_name': 'John',
        'last_name': 'Doe'
    }]
    valid, invalid = validate_records(records, 'customer')
    assert len(valid) == 1
    print("✓ Customer validation passed")
    
    # Product
    records = [{
        'product_id': 'PROD-001',
        'product_name': 'Test Product',
        'category': 'Electronics',
        'base_price': 99.99
    }]
    valid, invalid = validate_records(records, 'product')
    assert len(valid) == 1
    print("✓ Product validation passed")
    
    # Event
    records = [{
        'event_id': 'EVT-001',
        'event_type': 'page_view',
        'event_timestamp': '2025-01-27T10:00:00'
    }]
    valid, invalid = validate_records(records, 'event')
    assert len(valid) == 1
    print("✓ Event validation passed")
    
    print("All data type tests passed!\n")

@patch('lambda_function.s3_client')
def test_full_lambda_handler(mock_s3):
    """Test full Lambda handler with mocked S3 (no real AWS)"""
    print("Testing full Lambda handler with mocked AWS...")
    
    # Mock S3 put_object to not actually call AWS
    mock_s3.put_object.return_value = {'ETag': 'mock-etag'}
    
    # Valid event
    event = {
        'data_type': 'order',
        'records': [{
            'order_id': 'ORD-001',
            'customer_id': 'CUST-001',
            'product_id': 'PROD-001',
            'total_amount': 100.0,
            'quantity': 1,
            'status': 'pending'
        }]
    }
    
    response = lambda_handler(event, MockContext())
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['valid_records'] == 1
    assert 's3_location' in body
    
    # Verify S3 was called (mocked)
    assert mock_s3.put_object.called
    print("✓ Full handler test passed (S3 mocked)")
    print()

if __name__ == '__main__':
    print("="*60)
    print("Lambda Function Local Tests (No AWS Calls)")
    print("="*60 + "\n")
    
    try:
        test_validation()
        test_enrichment()
        test_different_data_types()
        test_full_lambda_handler()
        
        print("="*60)
        print("✅ ALL TESTS PASSED!")
        print("="*60)
        print("\nNote: These tests run locally without calling AWS.")
        print("To test with real AWS, deploy and use AWS CLI.")
        
    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
