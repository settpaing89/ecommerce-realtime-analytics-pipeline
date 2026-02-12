# src/orchestration/transform_lambda.py
"""
Lambda function to trigger ETL transformations
"""
import boto3
import os


def lambda_handler(event, context):
    """Run bronze to silver to gold transformations"""

    # Import your transformation code
    from transform_bronze_to_silver import main as bronze_to_silver
    from transform_silver_to_gold import main as silver_to_gold

    print("Starting transformations...")

    # Run bronze → silver
    print("Running Bronze → Silver...")
    bronze_to_silver()

    # Run silver → gold
    print("Running Silver → Gold...")
    silver_to_gold()

    return {"statusCode": 200, "body": "Transformations completed successfully"}
