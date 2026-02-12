"""
Manual Pipeline Execution Script
Runs the entire pipeline locally or triggers Step Functions
"""

import boto3
import os
import sys
import time
from datetime import datetime

# AWS clients
stepfunctions = boto3.client("stepfunctions")
glue = boto3.client("glue")

# Get environment variables
STATE_MACHINE_ARN = os.getenv("STATE_MACHINE_ARN")


def run_step_functions():
    """Trigger Step Functions execution"""
    print("=" * 60)
    print("Triggering Step Functions Pipeline")
    print("=" * 60)
    print()

    if not STATE_MACHINE_ARN:
        print("❌ STATE_MACHINE_ARN not set")
        print(
            "Run: export STATE_MACHINE_ARN=$(cd terraform && terraform output -raw step_functions_state_machine_arn)"
        )
        return False

    # Start execution
    execution_name = f"manual-run-{datetime.now().strftime('%Y%m%d-%H%M%S')}"

    print(f"Starting execution: {execution_name}")
    print(f"State Machine: {STATE_MACHINE_ARN}")
    print()

    response = stepfunctions.start_execution(
        stateMachineArn=STATE_MACHINE_ARN, name=execution_name, input="{}"
    )

    execution_arn = response["executionArn"]
    print(f"✅ Execution started!")
    print(f"Execution ARN: {execution_arn}")
    print()

    # Monitor execution
    print("Monitoring execution...")
    print("-" * 60)

    while True:
        response = stepfunctions.describe_execution(executionArn=execution_arn)

        status = response["status"]
        print(f"Status: {status}", end="\r")

        if status == "SUCCEEDED":
            print("\n✅ Pipeline completed successfully!          ")
            print()
            print("Output:")
            if "output" in response:
                print(response["output"])
            return True

        elif status in ["FAILED", "TIMED_OUT", "ABORTED"]:
            print(f"\n❌ Pipeline {status.lower()}              ")
            print()
            if "error" in response:
                print(f"Error: {response['error']}")
            if "cause" in response:
                print(f"Cause: {response['cause']}")
            return False

        time.sleep(5)


def run_local_pipeline():
    """Run pipeline steps locally"""
    print("=" * 60)
    print("Running Pipeline Locally")
    print("=" * 60)
    print()

    # Import transformation scripts
    sys.path.append("src/processing")

    try:
        # Step 1: Run transformations
        print("Step 1: Bronze → Silver transformation")
        print("-" * 60)
        from transform_bronze_to_silver import main as bronze_to_silver

        bronze_to_silver()
        print("✅ Bronze → Silver complete")
        print()

        # Step 2: Silver → Gold
        print("Step 2: Silver → Gold transformation")
        print("-" * 60)
        from transform_silver_to_gold import main as silver_to_gold

        silver_to_gold()
        print("✅ Silver → Gold complete")
        print()

        print("=" * 60)
        print("✅ Pipeline completed successfully!")
        print("=" * 60)

        return True

    except Exception as e:
        print(f"❌ Pipeline failed: {e}")
        import traceback

        traceback.print_exc()
        return False


def main():
    """Main function"""
    print()
    print("E-Commerce Analytics Pipeline Runner")
    print("=" * 60)
    print()
    print("Options:")
    print("  1. Run via Step Functions (AWS)")
    print("  2. Run locally (Python scripts)")
    print()

    choice = input("Choose option (1/2) or Enter for Step Functions: ").strip() or "1"
    print()

    if choice == "1":
        success = run_step_functions()
    elif choice == "2":
        success = run_local_pipeline()
    else:
        print("Invalid choice")
        return

    if success:
        print()
        print("Next steps:")
        print("  - View results in Athena")
        print("  - Check CloudWatch Logs for details")
        print("  - Query gold layer tables")


if __name__ == "__main__":
    main()
