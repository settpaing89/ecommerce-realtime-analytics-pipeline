"""
AWS Lambda Data Ingestion Function
Day 5: Real-time data ingestion with validation

This Lambda function:
1. Receives JSON data from API Gateway or S3 events
2. Validates schema and data quality
3. Enriches with metadata (timestamps, source)
4. Writes to S3 bronze layer as Parquet
5. Logs all operations to CloudWatch

Author: ASP
Date: 2025-01-27
"""

import json
import boto3
import pandas as pd
from datetime import datetime
from io import BytesIO
import os
import logging
from typing import Dict, List, Any, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client("s3")

# Environment variables
BRONZE_BUCKET = os.environ.get("BRONZE_BUCKET", "ecommerce-analytics-dev-bronze")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")

# Data schemas for validation
SCHEMAS = {
    "customer": {
        "required_fields": ["customer_id", "email", "first_name", "last_name"],
        "types": {
            "customer_id": str,
            "email": str,
            "first_name": str,
            "last_name": str,
            "phone": str,
            "is_active": bool,
        },
    },
    "product": {
        "required_fields": ["product_id", "product_name", "category", "base_price"],
        "types": {
            "product_id": str,
            "product_name": str,
            "category": str,
            "base_price": (int, float),
            "current_price": (int, float),
            "inventory_quantity": int,
        },
    },
    "order": {
        "required_fields": ["order_id", "customer_id", "product_id", "total_amount"],
        "types": {
            "order_id": str,
            "customer_id": str,
            "product_id": str,
            "order_date": str,
            "quantity": int,
            "total_amount": (int, float),
            "status": str,
        },
    },
    "event": {
        "required_fields": ["event_id", "event_type", "event_timestamp"],
        "types": {
            "event_id": str,
            "session_id": str,
            "event_type": str,
            "event_timestamp": str,
        },
    },
}


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler function

    Args:
        event: Lambda event (API Gateway or S3 event)
        context: Lambda context

    Returns:
        Response dict with status and message
    """
    try:
        logger.info(f"Lambda invoked with event: {json.dumps(event)}")

        # Determine event source
        if "Records" in event:
            # S3 event
            return handle_s3_event(event)
        elif "body" in event:
            # API Gateway event
            return handle_api_event(event)
        else:
            # Direct invocation with data
            return handle_direct_invocation(event)

    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}", exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e), "message": "Internal server error"}),
        }


def handle_api_event(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle API Gateway event

    Expected body format:
    {
        "data_type": "order",
        "records": [
            {"order_id": "ORD-001", ...},
            {"order_id": "ORD-002", ...}
        ]
    }
    """
    try:
        # Parse request body
        body = json.loads(event.get("body", "{}"))
        data_type = body.get("data_type")
        records = body.get("records", [])

        if not data_type or not records:
            return {
                "statusCode": 400,
                "body": json.dumps(
                    {
                        "error": "Missing data_type or records",
                        "message": "Request must include data_type and records",
                    }
                ),
            }

        logger.info(f"Processing {len(records)} {data_type} records")

        # Validate and process records
        valid_records, invalid_records = validate_records(records, data_type)

        if not valid_records:
            return {
                "statusCode": 400,
                "body": json.dumps(
                    {
                        "error": "No valid records",
                        "invalid_count": len(invalid_records),
                        "invalid_records": invalid_records[
                            :10
                        ],  # Return first 10 errors
                    }
                ),
            }

        # Enrich records
        enriched_records = enrich_records(valid_records, data_type)

        # Write to S3
        s3_key = write_to_s3(enriched_records, data_type)

        # Return success response
        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Data ingested successfully",
                    "data_type": data_type,
                    "valid_records": len(valid_records),
                    "invalid_records": len(invalid_records),
                    "s3_location": f"s3://{BRONZE_BUCKET}/{s3_key}",
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ),
        }

    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in request body: {str(e)}")
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid JSON", "message": str(e)}),
        }


def handle_s3_event(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle S3 event (triggered when file uploaded to S3)
    """
    try:
        processed_files = []

        for record in event["Records"]:
            bucket = record["s3"]["bucket"]["name"]
            key = record["s3"]["object"]["key"]

            logger.info(f"Processing S3 file: s3://{bucket}/{key}")

            # Download file
            response = s3_client.get_object(Bucket=bucket, Key=key)
            file_content = response["Body"].read()

            # Parse based on file extension
            if key.endswith(".json"):
                data = json.loads(file_content)
                records = data if isinstance(data, list) else [data]
            elif key.endswith(".csv"):
                df = pd.read_csv(BytesIO(file_content))
                records = df.to_dict("records")
            else:
                logger.warning(f"Unsupported file type: {key}")
                continue

            # Infer data type from key or content
            data_type = infer_data_type(key, records)

            # Process records
            valid_records, _ = validate_records(records, data_type)
            enriched_records = enrich_records(valid_records, data_type)
            s3_key = write_to_s3(enriched_records, data_type)

            processed_files.append(
                {
                    "source_file": f"s3://{bucket}/{key}",
                    "destination": f"s3://{BRONZE_BUCKET}/{s3_key}",
                    "record_count": len(enriched_records),
                }
            )

        return {
            "statusCode": 200,
            "body": json.dumps(
                {"message": "S3 files processed successfully", "files": processed_files}
            ),
        }

    except Exception as e:
        logger.error(f"Error processing S3 event: {str(e)}", exc_info=True)
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}


def handle_direct_invocation(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle direct Lambda invocation (for testing)
    """
    data_type = event.get("data_type", "order")
    records = event.get("records", [])

    logger.info(f"Direct invocation with {len(records)} {data_type} records")

    if not records:
        return {"statusCode": 400, "body": json.dumps({"error": "No records provided"})}

    valid_records, invalid_records = validate_records(records, data_type)
    enriched_records = enrich_records(valid_records, data_type)
    s3_key = write_to_s3(enriched_records, data_type)

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Success",
                "valid_records": len(valid_records),
                "invalid_records": len(invalid_records),
                "s3_location": f"s3://{BRONZE_BUCKET}/{s3_key}",
            }
        ),
    }


def validate_records(records: List[Dict], data_type: str) -> tuple:
    """
    Validate records against schema

    Returns:
        (valid_records, invalid_records)
    """
    if data_type not in SCHEMAS:
        logger.warning(f"Unknown data type: {data_type}, skipping validation")
        return records, []

    schema = SCHEMAS[data_type]
    valid = []
    invalid = []

    for idx, record in enumerate(records):
        errors = []

        # Check required fields
        for field in schema["required_fields"]:
            if field not in record or record[field] is None:
                errors.append(f"Missing required field: {field}")

        # Check data types
        for field, expected_type in schema["types"].items():
            if field in record and record[field] is not None:
                if not isinstance(record[field], expected_type):
                    errors.append(
                        f"Invalid type for {field}: expected {expected_type}, "
                        f"got {type(record[field])}"
                    )

        # Business rules validation
        if data_type == "order":
            if "total_amount" in record and record["total_amount"] <= 0:
                errors.append("total_amount must be positive")
            if "quantity" in record and record["quantity"] <= 0:
                errors.append("quantity must be positive")

        if data_type == "product":
            if "base_price" in record and record["base_price"] <= 0:
                errors.append("base_price must be positive")

        if errors:
            invalid.append({"record_index": idx, "errors": errors, "record": record})
            logger.warning(f"Invalid record at index {idx}: {errors}")
        else:
            valid.append(record)

    logger.info(f"Validation complete: {len(valid)} valid, {len(invalid)} invalid")
    return valid, invalid


def enrich_records(records: List[Dict], data_type: str) -> List[Dict]:
    """
    Enrich records with metadata
    """
    enriched = []
    current_time = datetime.utcnow().isoformat()

    for record in records:
        enriched_record = record.copy()

        # Add metadata
        enriched_record["_ingestion_timestamp"] = current_time
        enriched_record["_source"] = "lambda_ingestion"
        enriched_record["_data_type"] = data_type
        enriched_record["_environment"] = ENVIRONMENT
        enriched_record["_version"] = "1.0"

        # Data type specific enrichment
        if data_type == "order" and "order_date" in enriched_record:
            # Parse order date and add date components
            try:
                order_date = pd.to_datetime(enriched_record["order_date"])
                enriched_record["_order_year"] = order_date.year
                enriched_record["_order_month"] = order_date.month
                enriched_record["_order_day"] = order_date.day
            except:
                pass

        enriched.append(enriched_record)

    logger.info(f"Enriched {len(enriched)} records")
    return enriched


def write_to_s3(records: List[Dict], data_type: str) -> str:
    """
    Write records to S3 as Parquet

    Returns:
        S3 key of written file
    """
    if not records:
        raise ValueError("No records to write")

    # Convert to DataFrame
    df = pd.DataFrame(records)

    # Generate S3 key with partitioning
    now = datetime.utcnow()
    s3_key = (
        f"{data_type}s/"  # e.g., orders/, customers/
        f"year={now.year}/"
        f"month={now.month:02d}/"
        f"day={now.day:02d}/"
        f"{data_type}_{now.strftime('%Y%m%d_%H%M%S')}.parquet"
    )

    # Write to buffer
    buffer = BytesIO()
    df.to_parquet(buffer, index=False, compression="snappy")
    buffer.seek(0)

    # Upload to S3
    s3_client.put_object(
        Bucket=BRONZE_BUCKET,
        Key=s3_key,
        Body=buffer.getvalue(),
        ContentType="application/octet-stream",
        Metadata={
            "record_count": str(len(records)),
            "data_type": data_type,
            "ingestion_timestamp": datetime.utcnow().isoformat(),
        },
    )

    logger.info(f"Wrote {len(records)} records to s3://{BRONZE_BUCKET}/{s3_key}")
    return s3_key


def infer_data_type(filename: str, records: List[Dict]) -> str:
    """
    Infer data type from filename or record structure
    """
    filename_lower = filename.lower()

    if "customer" in filename_lower:
        return "customer"
    elif "product" in filename_lower:
        return "product"
    elif "order" in filename_lower:
        return "order"
    elif "event" in filename_lower:
        return "event"

    # Try to infer from record keys
    if records:
        keys = set(records[0].keys())
        if "order_id" in keys:
            return "order"
        elif "customer_id" in keys and "email" in keys:
            return "customer"
        elif "product_id" in keys and "product_name" in keys:
            return "product"
        elif "event_id" in keys:
            return "event"

    # Default
    return "unknown"


# For local testing
if __name__ == "__main__":
    # Test with sample data
    test_event = {
        "data_type": "order",
        "records": [
            {
                "order_id": "ORD-TEST-001",
                "customer_id": "CUST-000001",
                "product_id": "PROD-0001",
                "order_date": "2025-01-27T10:30:00",
                "quantity": 2,
                "total_amount": 99.98,
                "status": "pending",
            },
            {
                "order_id": "ORD-TEST-002",
                "customer_id": "CUST-000002",
                "product_id": "PROD-0002",
                "order_date": "2025-01-27T11:00:00",
                "quantity": 1,
                "total_amount": 49.99,
                "status": "confirmed",
            },
        ],
    }

    # Mock context
    class MockContext:
        function_name = "test-function"
        memory_limit_in_mb = 256
        invoked_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:test"
        aws_request_id = "test-request-id"

    # Run test
    response = lambda_handler(test_event, MockContext())
    print(json.dumps(response, indent=2))
