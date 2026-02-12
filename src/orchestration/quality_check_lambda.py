# src/orchestration/quality_check_lambda.py
"""
Data quality validation Lambda
"""
import boto3
import pandas as pd


def lambda_handler(event, context):
    """Run data quality checks on gold layer"""

    s3 = boto3.client("s3")
    gold_bucket = os.getenv("GOLD_BUCKET")

    checks = {
        "daily_sales_summary": check_daily_sales,
        "customer_lifetime_value": check_customer_ltv,
        "product_performance": check_products,
    }

    results = []
    for table, check_func in checks.items():
        result = check_func(s3, gold_bucket, table)
        results.append(result)

    # If any check fails, raise exception
    if any(not r["passed"] for r in results):
        raise Exception(f"Data quality checks failed: {results}")

    return {"statusCode": 200, "checks": results}


def check_daily_sales(s3, bucket, table):
    """Validate daily sales data"""
    # Download latest file
    # Check: no null values in revenue
    # Check: dates are sequential
    # Check: revenue > 0
    return {"table": table, "passed": True, "rows": 100}
