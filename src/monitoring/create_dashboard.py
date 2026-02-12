"""
Create CloudWatch Dashboard for Pipeline Monitoring
"""

import boto3
import os
import json
import sys


def create_dashboard():
    """Create CloudWatch dashboard"""

    print("=" * 60)
    print("Creating CloudWatch Dashboard")
    print("=" * 60)
    print()

    try:
        cloudwatch = boto3.client("cloudwatch")

        project_name = os.getenv("PROJECT_NAME", "ecommerce-analytics")
        environment = os.getenv("ENVIRONMENT", "dev")
        aws_region = os.getenv("AWS_REGION", "us-east-1")

        dashboard_name = f"{project_name}-{environment}-pipeline-monitoring"

        print(f"Dashboard name: {dashboard_name}")
        print(f"Region: {aws_region}")
        print()

        dashboard_body = {
            "widgets": [
                {
                    "type": "metric",
                    "x": 0,
                    "y": 0,
                    "width": 12,
                    "height": 6,
                    "properties": {
                        "metrics": [
                            [
                                "AWS/States",
                                "ExecutionsSucceeded",
                                {"stat": "Sum", "label": "Successful"},
                            ],
                            [
                                ".",
                                "ExecutionsFailed",
                                {"stat": "Sum", "label": "Failed"},
                            ],
                            [
                                ".",
                                "ExecutionsTimedOut",
                                {"stat": "Sum", "label": "Timed Out"},
                            ],
                        ],
                        "period": 300,
                        "stat": "Sum",
                        "region": aws_region,
                        "title": "Pipeline Executions (Last 24 Hours)",
                        "yAxis": {"left": {"min": 0}},
                    },
                },
                {
                    "type": "metric",
                    "x": 12,
                    "y": 0,
                    "width": 12,
                    "height": 6,
                    "properties": {
                        "metrics": [
                            [
                                "AWS/States",
                                "ExecutionTime",
                                {"stat": "Average", "label": "Avg Duration"},
                            ],
                            ["...", {"stat": "Maximum", "label": "Max Duration"}],
                        ],
                        "period": 300,
                        "stat": "Average",
                        "region": aws_region,
                        "title": "Execution Duration (seconds)",
                        "yAxis": {"left": {"min": 0}},
                    },
                },
                {
                    "type": "log",
                    "x": 0,
                    "y": 6,
                    "width": 24,
                    "height": 6,
                    "properties": {
                        "query": f"SOURCE '/aws/vendedlogs/states/{project_name}-{environment}-pipeline'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 20",
                        "region": aws_region,
                        "title": "Recent Pipeline Logs",
                        "stacked": False,
                    },
                },
            ]
        }

        print("Creating dashboard...")

        response = cloudwatch.put_dashboard(
            DashboardName=dashboard_name, DashboardBody=json.dumps(dashboard_body)
        )

        print()
        print("✅ Dashboard created successfully!")
        print()
        print(f"Dashboard name: {dashboard_name}")
        print(
            f"View at: https://console.aws.amazon.com/cloudwatch/home?region={aws_region}#dashboards:name={dashboard_name}"
        )
        print()

        return True

    except Exception as e:
        print()
        print(f"❌ Error creating dashboard: {e}")
        print()
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = create_dashboard()
    sys.exit(0 if success else 1)
