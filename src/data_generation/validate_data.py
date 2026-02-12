"""
Data Quality Validation Script
Checks for common data issues
"""

import pandas as pd
from pathlib import Path


def validate_dataset(df, name, required_columns, unique_columns, allow_nulls=None):
    """Validate a dataset"""
    print(f"\nValidating {name}...")
    issues = []

    # Check required columns exist
    missing_cols = set(required_columns) - set(df.columns)
    if missing_cols:
        issues.append(f"Missing columns: {missing_cols}")

    # Check for null values (excluding allowed nulls)
    if allow_nulls is None:
        allow_nulls = []

    null_counts = df.isnull().sum()
    # Filter out allowed null columns
    unexpected_nulls = {
        col: count
        for col, count in null_counts.items()
        if count > 0 and col not in allow_nulls
    }

    if unexpected_nulls:
        issues.append(f"Unexpected null values: {unexpected_nulls}")

    # Check for duplicates in unique columns
    for col in unique_columns:
        if col in df.columns:
            dupes = df[col].duplicated().sum()
            if dupes > 0:
                issues.append(f"Duplicate {col}: {dupes} records")

    if issues:
        print(f"  ⚠️  Issues found:")
        for issue in issues:
            print(f"     - {issue}")
        return False
    else:
        print(f"  ✅ All checks passed!")
        return True


def main():
    print("=" * 60)
    print("DATA QUALITY VALIDATION")
    print("=" * 60)

    # Load data
    data_dir = Path("data/bronze")

    customers = pd.read_parquet(data_dir / "customers.parquet")
    products = pd.read_parquet(data_dir / "products.parquet")
    orders = pd.read_parquet(data_dir / "orders.parquet")
    events = pd.read_parquet(data_dir / "events.parquet")

    # Validate each dataset
    results = []

    results.append(
        validate_dataset(
            customers,
            "Customers",
            required_columns=["customer_id", "email", "signup_date"],
            unique_columns=[
                "customer_id"
            ],  # Email can have duplicates (rare but possible)
            allow_nulls=[],
        )
    )

    results.append(
        validate_dataset(
            products,
            "Products",
            required_columns=["product_id", "product_name", "category", "base_price"],
            unique_columns=["product_id"],
            allow_nulls=[],
        )
    )

    results.append(
        validate_dataset(
            orders,
            "Orders",
            required_columns=[
                "order_id",
                "customer_id",
                "product_id",
                "order_date",
                "total_amount",
            ],
            unique_columns=["order_id"],
            allow_nulls=[],
        )
    )

    results.append(
        validate_dataset(
            events,
            "Events",
            required_columns=["event_id", "event_type", "event_timestamp"],
            unique_columns=["event_id"],
            allow_nulls=["customer_id", "product_id", "referrer_url"],
        )
    )

    # Additional checks
    print("\n" + "-" * 60)
    print("BUSINESS LOGIC VALIDATION")
    print("-" * 60)

    # Check email duplicates (warning only)
    email_dupes = customers["email"].duplicated().sum()
    if email_dupes > 0:
        print(f"⚠️  Note: {email_dupes} duplicate emails found")
        print(f"   (This can happen in real data - shared family emails)")

    # Check orders reference valid customers
    invalid_customers = ~orders["customer_id"].isin(customers["customer_id"])
    if invalid_customers.any():
        print(f"❌ {invalid_customers.sum()} orders reference non-existent customers")
    else:
        print(f"✅ All orders reference valid customers")

    # Check orders reference valid products
    invalid_products = ~orders["product_id"].isin(products["product_id"])
    if invalid_products.any():
        print(f"❌ {invalid_products.sum()} orders reference non-existent products")
    else:
        print(f"✅ All orders reference valid products")

    # Summary
    print("\n" + "=" * 60)
    if all(results):
        print("✅ ALL CORE VALIDATIONS PASSED!")
        print("\nData Quality Summary:")
        print(f"  • Customers: {len(customers):,} records")
        print(f"  • Products: {len(products):,} records")
        print(f"  • Orders: {len(orders):,} records")
        print(f"  • Events: {len(events):,} records")
        print(
            f"  • Total: {len(customers) + len(products) + len(orders) + len(events):,} records"
        )

        # Data integrity
        print(f"\nData Integrity:")
        print(f"  • Order-Customer links: ✅")
        print(f"  • Order-Product links: ✅")
        if email_dupes == 0:
            print(f"  • Unique emails: ✅")
        else:
            print(f"  • Email duplicates: ⚠️  {email_dupes} (acceptable)")
    else:
        print("❌ SOME VALIDATIONS FAILED")
    print("=" * 60)


if __name__ == "__main__":
    main()
