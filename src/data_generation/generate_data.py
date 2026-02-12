"""
E-Commerce Data Generator
Day 3: Generate realistic e-commerce data for the pipeline

This script generates:
- Orders (10,000 records)
- Customers (1,000 records)
- Products (100 records)
- Events (20,000 records - web activity)

Saves data as Parquet files in data/bronze/ directory
"""

import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta
import random
import os
from pathlib import Path

# Initialize Faker
fake = Faker()
Faker.seed(42)  # For reproducibility
random.seed(42)
np.random.seed(42)

# Configuration
NUM_CUSTOMERS = 1000
NUM_PRODUCTS = 100
NUM_ORDERS = 10000
NUM_EVENTS = 20000

# Product categories
CATEGORIES = [
    "Electronics",
    "Clothing",
    "Home & Kitchen",
    "Books",
    "Toys & Games",
    "Sports",
    "Beauty",
    "Grocery",
]

# Event types
EVENT_TYPES = [
    "page_view",
    "product_view",
    "add_to_cart",
    "remove_from_cart",
    "checkout_start",
    "purchase",
]

# Payment methods
PAYMENT_METHODS = ["credit_card", "debit_card", "paypal", "apple_pay", "google_pay"]

# Order statuses
ORDER_STATUSES = ["pending", "confirmed", "shipped", "delivered", "cancelled"]


def create_output_dir():
    """Create output directory if it doesn't exist"""
    output_dir = Path("data/bronze")
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def generate_customers(num_customers):
    """Generate customer data"""
    print(f"Generating {num_customers} customers...")

    customers = []
    for i in range(num_customers):
        customer = {
            "customer_id": f"CUST-{i+1:06d}",
            "first_name": fake.first_name(),
            "last_name": fake.last_name(),
            "email": fake.email(),
            "phone": fake.phone_number(),
            "date_of_birth": fake.date_of_birth(minimum_age=18, maximum_age=80),
            "gender": random.choice(["M", "F", "Other"]),
            "city": fake.city(),
            "state": fake.state(),
            "country": "USA",
            "postal_code": fake.zipcode(),
            "signup_date": fake.date_time_between(start_date="-2y", end_date="now"),
            "customer_segment": random.choice(["Premium", "Regular", "New"]),
            "is_active": random.choice([True, True, True, False]),  # 75% active
        }
        customers.append(customer)

    df = pd.DataFrame(customers)
    print(f"✓ Generated {len(df)} customers")
    return df


def generate_products(num_products):
    """Generate product catalog"""
    print(f"Generating {num_products} products...")

    products = []
    for i in range(num_products):
        category = random.choice(CATEGORIES)
        base_price = round(random.uniform(5.99, 999.99), 2)

        product = {
            "product_id": f"PROD-{i+1:04d}",
            "product_name": fake.catch_phrase(),
            "category": category,
            "subcategory": f'{category} - {random.choice(["Type A", "Type B", "Type C"])}',
            "brand": fake.company(),
            "base_price": base_price,
            "current_price": round(
                base_price * random.uniform(0.8, 1.2), 2
            ),  # Price variation
            "cost": round(
                base_price * random.uniform(0.4, 0.7), 2
            ),  # Cost is 40-70% of base price
            "inventory_quantity": random.randint(0, 500),
            "weight_kg": round(random.uniform(0.1, 20.0), 2),
            "rating": round(random.uniform(3.0, 5.0), 1),
            "num_reviews": random.randint(0, 1000),
            "is_active": random.choice([True, True, True, False]),  # 75% active
            "created_date": fake.date_time_between(start_date="-3y", end_date="-1y"),
        }
        products.append(product)

    df = pd.DataFrame(products)
    print(f"✓ Generated {len(df)} products")
    return df


def generate_orders(num_orders, customers_df, products_df):
    """Generate order transactions"""
    print(f"Generating {num_orders} orders...")

    # Filter active customers and products
    active_customers = customers_df[customers_df["is_active"]]["customer_id"].tolist()
    active_products = products_df[products_df["is_active"]]["product_id"].tolist()

    orders = []
    for i in range(num_orders):
        customer_id = random.choice(active_customers)
        product_id = random.choice(active_products)

        # Get product price
        product_price = products_df[products_df["product_id"] == product_id][
            "current_price"
        ].values[0]

        # Generate order details
        quantity = random.randint(1, 5)
        order_date = fake.date_time_between(start_date="-90d", end_date="now")

        # Calculate amounts
        subtotal = round(product_price * quantity, 2)
        tax = round(subtotal * 0.08, 2)  # 8% tax
        shipping = (
            round(random.uniform(0, 15.99), 2) if subtotal < 50 else 0
        )  # Free shipping over $50
        total_amount = round(subtotal + tax + shipping, 2)

        # Determine status based on order age
        days_ago = (datetime.now() - order_date).days
        if days_ago < 1:
            status = random.choice(["pending", "confirmed"])
        elif days_ago < 3:
            status = random.choice(["confirmed", "shipped"])
        elif days_ago < 7:
            status = random.choice(["shipped", "delivered"])
        else:
            status = random.choice(
                ["delivered", "delivered", "delivered", "cancelled"]
            )  # Mostly delivered

        order = {
            "order_id": f"ORD-{i+1:08d}",
            "customer_id": customer_id,
            "product_id": product_id,
            "order_date": order_date,
            "quantity": quantity,
            "unit_price": product_price,
            "subtotal": subtotal,
            "tax": tax,
            "shipping_cost": shipping,
            "total_amount": total_amount,
            "payment_method": random.choice(PAYMENT_METHODS),
            "status": status,
            "shipping_address": fake.address(),
            "billing_address": fake.address()
            if random.random() > 0.7
            else fake.address(),  # 30% different
            "created_at": order_date,
            "updated_at": order_date + timedelta(days=random.randint(0, days_ago)),
        }
        orders.append(order)

    df = pd.DataFrame(orders)
    print(f"✓ Generated {len(df)} orders")
    return df


def generate_events(num_events, customers_df, products_df):
    """Generate web events (clickstream data)"""
    print(f"Generating {num_events} events...")

    active_customers = customers_df[customers_df["is_active"]]["customer_id"].tolist()
    active_products = products_df[products_df["is_active"]]["product_id"].tolist()

    events = []
    for i in range(num_events):
        event_time = fake.date_time_between(start_date="-30d", end_date="now")

        event = {
            "event_id": f"EVT-{i+1:08d}",
            "customer_id": random.choice(active_customers)
            if random.random() > 0.2
            else None,  # 20% anonymous
            "session_id": fake.uuid4(),
            "event_type": random.choice(EVENT_TYPES),
            "product_id": random.choice(active_products)
            if random.random() > 0.3
            else None,  # 70% product-related
            "event_timestamp": event_time,
            "page_url": fake.uri(),
            "referrer_url": fake.uri() if random.random() > 0.5 else None,
            "device_type": random.choice(["mobile", "desktop", "tablet"]),
            "browser": random.choice(["Chrome", "Safari", "Firefox", "Edge"]),
            "ip_address": fake.ipv4(),
            "country": "USA",
            "city": fake.city(),
        }
        events.append(event)

    df = pd.DataFrame(events)
    print(f"✓ Generated {len(df)} events")
    return df


def save_to_parquet(df, filename, output_dir):
    """Save DataFrame to Parquet format"""
    filepath = output_dir / f"{filename}.parquet"
    df.to_parquet(filepath, index=False, compression="snappy")

    # Get file size
    size_mb = filepath.stat().st_size / (1024 * 1024)
    print(f"✓ Saved {filename}.parquet ({size_mb:.2f} MB)")
    return filepath


def generate_data_quality_report(customers_df, products_df, orders_df, events_df):
    """Generate a data quality report"""
    print("\n" + "=" * 60)
    print("DATA QUALITY REPORT")
    print("=" * 60)

    report = {
        "Customers": {
            "Total Records": len(customers_df),
            "Active Customers": customers_df["is_active"].sum(),
            "Null Values": customers_df.isnull().sum().sum(),
            "Duplicate IDs": customers_df["customer_id"].duplicated().sum(),
            "Date Range": f"{customers_df['signup_date'].min()} to {customers_df['signup_date'].max()}",
        },
        "Products": {
            "Total Records": len(products_df),
            "Active Products": products_df["is_active"].sum(),
            "Null Values": products_df.isnull().sum().sum(),
            "Duplicate IDs": products_df["product_id"].duplicated().sum(),
            "Categories": products_df["category"].nunique(),
            "Price Range": f"${products_df['current_price'].min():.2f} - ${products_df['current_price'].max():.2f}",
        },
        "Orders": {
            "Total Records": len(orders_df),
            "Total Revenue": f"${orders_df['total_amount'].sum():,.2f}",
            "Average Order Value": f"${orders_df['total_amount'].mean():.2f}",
            "Null Values": orders_df.isnull().sum().sum(),
            "Duplicate IDs": orders_df["order_id"].duplicated().sum(),
            "Date Range": f"{orders_df['order_date'].min()} to {orders_df['order_date'].max()}",
            "Status Breakdown": orders_df["status"].value_counts().to_dict(),
        },
        "Events": {
            "Total Records": len(events_df),
            "Anonymous Events": events_df["customer_id"].isnull().sum(),
            "Event Types": events_df["event_type"].value_counts().to_dict(),
            "Null Values": events_df.isnull().sum().sum(),
            "Date Range": f"{events_df['event_timestamp'].min()} to {events_df['event_timestamp'].max()}",
        },
    }

    for dataset, metrics in report.items():
        print(f"\n{dataset}:")
        for metric, value in metrics.items():
            print(f"  {metric}: {value}")

    print("\n" + "=" * 60)
    return report


def main():
    """Main execution function"""
    print("\n" + "=" * 60)
    print("E-COMMERCE DATA GENERATOR")
    print("=" * 60 + "\n")

    # Create output directory
    output_dir = create_output_dir()
    print(f"Output directory: {output_dir}\n")

    # Generate datasets
    print("STEP 1: Generating Datasets")
    print("-" * 60)
    customers_df = generate_customers(NUM_CUSTOMERS)
    products_df = generate_products(NUM_PRODUCTS)
    orders_df = generate_orders(NUM_ORDERS, customers_df, products_df)
    events_df = generate_events(NUM_EVENTS, customers_df, products_df)

    # Save to Parquet
    print("\nSTEP 2: Saving to Parquet Files")
    print("-" * 60)
    save_to_parquet(customers_df, "customers", output_dir)
    save_to_parquet(products_df, "products", output_dir)
    save_to_parquet(orders_df, "orders", output_dir)
    save_to_parquet(events_df, "events", output_dir)

    # Generate quality report
    print("\nSTEP 3: Data Quality Check")
    print("-" * 60)
    generate_data_quality_report(customers_df, products_df, orders_df, events_df)

    # Summary
    total_size = sum(f.stat().st_size for f in output_dir.glob("*.parquet")) / (
        1024 * 1024
    )
    print(f"\n✅ SUCCESS!")
    print(
        f"Generated 4 datasets with {NUM_CUSTOMERS + NUM_PRODUCTS + NUM_ORDERS + NUM_EVENTS:,} total records"
    )
    print(f"Total size: {total_size:.2f} MB")
    print(f"Location: {output_dir.absolute()}")
    print("\nNext steps:")
    print("1. Verify data: ls -lh data/bronze/")
    print("2. Upload to S3 (Day 4)")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
