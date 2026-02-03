#!/bin/bash

echo "========================================"
echo "Quick Fix: Generate More Data"
echo "========================================"
echo ""

# Get bucket names
export BRONZE_BUCKET=$(cd terraform && terraform output -raw bronze_bucket_name 2>/dev/null)
export SILVER_BUCKET=$(cd terraform && terraform output -raw silver_bucket_name 2>/dev/null)
export GOLD_BUCKET=$(cd terraform && terraform output -raw gold_bucket_name 2>/dev/null)
export GLUE_DATABASE=$(cd terraform && terraform output -raw glue_database_name 2>/dev/null)

echo "Target Buckets:"
echo "  Bronze: $BRONZE_BUCKET"
echo "  Silver: $SILVER_BUCKET"
echo "  Gold: $GOLD_BUCKET"
echo ""

# Check if data generation scripts exist
if [ ! -d "src/data_generation" ]; then
    echo "❌ Data generation directory not found"
    echo ""
    echo "Creating basic data generator..."
    
    mkdir -p src/data_generation
    
    # Create a comprehensive data generator
    cat > src/data_generation/generate_all_data.py << 'PYEOF'
"""
Generate comprehensive e-commerce sample data
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from faker import Faker
import random
import os

fake = Faker()
Faker.seed(42)
np.random.seed(42)

def generate_customers(num_customers=1000):
    """Generate customer data"""
    print(f"Generating {num_customers} customers...")
    
    customers = []
    for i in range(num_customers):
        customers.append({
            'customer_id': f'CUST_{i+1:06d}',
            'email': fake.email(),
            'first_name': fake.first_name(),
            'last_name': fake.last_name(),
            'phone': fake.phone_number(),
            'address': fake.street_address(),
            'city': fake.city(),
            'state': fake.state_abbr(),
            'zip_code': fake.zipcode(),
            'country': 'USA',
            'date_of_birth': fake.date_of_birth(minimum_age=18, maximum_age=80),
            'created_at': fake.date_time_between(start_date='-2y', end_date='now'),
        })
    
    df = pd.DataFrame(customers)
    print(f"✅ Generated {len(df)} customers")
    return df

def generate_products(num_products=200):
    """Generate product data"""
    print(f"Generating {num_products} products...")
    
    categories = ['Electronics', 'Clothing', 'Home & Garden', 'Sports', 'Books', 
                  'Toys', 'Food & Beverage', 'Health & Beauty', 'Automotive']
    
    products = []
    for i in range(num_products):
        category = random.choice(categories)
        base_price = round(random.uniform(9.99, 999.99), 2)
        cost = round(base_price * random.uniform(0.3, 0.7), 2)
        
        products.append({
            'product_id': f'PROD_{i+1:06d}',
            'product_name': fake.catch_phrase(),
            'category': category,
            'brand': fake.company(),
            'base_price': base_price,
            'current_price': round(base_price * random.uniform(0.8, 1.0), 2),
            'cost': cost,
            'inventory_quantity': random.randint(0, 500),
            'description': fake.text(max_nb_chars=200),
            'created_at': fake.date_time_between(start_date='-1y', end_date='now'),
        })
    
    df = pd.DataFrame(products)
    print(f"✅ Generated {len(df)} products")
    return df

def generate_orders(num_orders=5000, customers_df=None, products_df=None):
    """Generate order data spanning multiple days"""
    print(f"Generating {num_orders} orders...")
    
    # Generate orders over 60 days
    end_date = datetime.now()
    start_date = end_date - timedelta(days=60)
    
    orders = []
    order_id = 1
    
    for i in range(num_orders):
        # Random date within range
        days_ago = random.randint(0, 60)
        order_date = end_date - timedelta(days=days_ago)
        
        # Random customer
        customer_id = random.choice(customers_df['customer_id'].tolist()) if customers_df is not None else f'CUST_{random.randint(1, 1000):06d}'
        
        # Random product
        product = products_df.iloc[random.randint(0, len(products_df)-1)] if products_df is not None else None
        product_id = product['product_id'] if product is not None else f'PROD_{random.randint(1, 200):06d}'
        
        # Order details
        quantity = random.randint(1, 5)
        unit_price = product['current_price'] if product is not None else random.uniform(10, 500)
        subtotal = round(quantity * unit_price, 2)
        tax = round(subtotal * 0.08, 2)
        shipping = round(random.choice([0, 5.99, 9.99, 14.99]), 2)
        total_amount = round(subtotal + tax + shipping, 2)
        
        orders.append({
            'order_id': f'ORD_{order_id:08d}',
            'customer_id': customer_id,
            'product_id': product_id,
            'order_date': order_date,
            'quantity': quantity,
            'unit_price': round(unit_price, 2),
            'subtotal': subtotal,
            'tax': tax,
            'shipping': shipping,
            'total_amount': total_amount,
            'status': random.choice(['delivered', 'delivered', 'delivered', 'shipped', 'pending']),
            'payment_method': random.choice(['credit_card', 'paypal', 'debit_card']),
            'created_at': order_date,
        })
        
        order_id += 1
    
    df = pd.DataFrame(orders)
    print(f"✅ Generated {len(df)} orders")
    print(f"   Date range: {df['order_date'].min()} to {df['order_date'].max()}")
    print(f"   Total revenue: ${df['total_amount'].sum():,.2f}")
    return df

def main():
    """Generate all data and save to parquet files"""
    print("="*60)
    print("E-Commerce Data Generator")
    print("="*60)
    print()
    
    # Create output directory
    os.makedirs('data/bronze', exist_ok=True)
    
    # Generate data
    customers_df = generate_customers(num_customers=1000)
    products_df = generate_products(num_products=200)
    orders_df = generate_orders(num_orders=5000, customers_df=customers_df, products_df=products_df)
    
    # Save to parquet
    print("\nSaving data to Parquet files...")
    
    customers_path = 'data/bronze/customers.parquet'
    products_path = 'data/bronze/products.parquet'
    orders_path = 'data/bronze/orders.parquet'
    
    customers_df.to_parquet(customers_path, index=False, compression='snappy')
    print(f"✅ Saved: {customers_path} ({os.path.getsize(customers_path)/1024:.1f} KB)")
    
    products_df.to_parquet(products_path, index=False, compression='snappy')
    print(f"✅ Saved: {products_path} ({os.path.getsize(products_path)/1024:.1f} KB)")
    
    orders_df.to_parquet(orders_path, index=False, compression='snappy')
    print(f"✅ Saved: {orders_path} ({os.path.getsize(orders_path)/1024:.1f} KB)")
    
    print("\n" + "="*60)
    print("✅ Data Generation Complete!")
    print("="*60)
    print("\nSummary:")
    print(f"  Customers: {len(customers_df):,} records")
    print(f"  Products: {len(products_df):,} records")
    print(f"  Orders: {len(orders_df):,} records")
    print(f"  Total Size: {(os.path.getsize(customers_path) + os.path.getsize(products_path) + os.path.getsize(orders_path))/1024/1024:.2f} MB")
    print("\nNext steps:")
    print("  1. Upload to S3: ./scripts/quick_fix_data.sh upload")
    print("  2. Run transformations: ./scripts/quick_fix_data.sh transform")
    print("  3. Query in Athena")

if __name__ == '__main__':
    main()
PYEOF

    chmod +x src/data_generation/generate_all_data.py
    echo "✅ Created data generator"
fi

# Function to generate data
generate_data() {
    echo "Step 1: Generating sample data..."
    echo "================================"
    python3 src/data_generation/generate_all_data.py
    
    if [ $? -ne 0 ]; then
        echo "❌ Data generation failed"
        echo "Installing required packages..."
        pip install faker pandas pyarrow
        python3 src/data_generation/generate_all_data.py
    fi
    echo ""
}

# Function to upload to S3
upload_to_s3() {
    echo "Step 2: Uploading to S3 Bronze Layer..."
    echo "========================================"
    
    if [ ! -d "data/bronze" ]; then
        echo "❌ No data/bronze directory found. Run: $0 generate"
        exit 1
    fi
    
    # Upload with date partitioning
    current_date=$(date +%Y-%m-%d)
    year=$(date +%Y)
    month=$(date +%m)
    day=$(date +%d)
    
    echo "Uploading customers..."
    aws s3 cp data/bronze/customers.parquet \
        s3://$BRONZE_BUCKET/customers/year=$year/month=$month/day=$day/customers_${current_date}.parquet
    
    echo "Uploading products..."
    aws s3 cp data/bronze/products.parquet \
        s3://$BRONZE_BUCKET/products/year=$year/month=$month/day=$day/products_${current_date}.parquet
    
    echo "Uploading orders..."
    aws s3 cp data/bronze/orders.parquet \
        s3://$BRONZE_BUCKET/orders/year=$year/month=$month/day=$day/orders_${current_date}.parquet
    
    echo ""
    echo "✅ Upload complete!"
    echo ""
    echo "Verifying upload..."
    echo "Customers:"
    aws s3 ls s3://$BRONZE_BUCKET/customers/ --recursive | tail -2
    echo ""
    echo "Products:"
    aws s3 ls s3://$BRONZE_BUCKET/products/ --recursive | tail -2
    echo ""
    echo "Orders:"
    aws s3 ls s3://$BRONZE_BUCKET/orders/ --recursive | tail -2
    echo ""
}

# Function to run transformations
run_transformations() {
    echo "Step 3: Running Transformations..."
    echo "==================================="
    
    echo "Bronze → Silver..."
    python3 src/processing/transform_bronze_to_silver.py
    
    if [ $? -eq 0 ]; then
        echo "✅ Bronze → Silver complete"
    else
        echo "❌ Bronze → Silver failed"
        exit 1
    fi
    
    echo ""
    echo "Silver → Gold..."
    python3 src/processing/transform_silver_to_gold.py
    
    if [ $? -eq 0 ]; then
        echo "✅ Silver → Gold complete"
    else
        echo "❌ Silver → Gold failed"
        exit 1
    fi
    
    echo ""
}

# Function to repair Athena partitions
repair_partitions() {
    echo "Step 4: Repairing Athena Partitions..."
    echo "======================================="
    
    tables=("daily_sales_summary" "customer_lifetime_value" "product_performance" "conversion_funnel")
    
    for table in "${tables[@]}"; do
        echo "Repairing $table..."
        
        EXEC_ID=$(aws athena start-query-execution \
            --query-string "MSCK REPAIR TABLE $table" \
            --query-execution-context Database=$GLUE_DATABASE \
            --result-configuration OutputLocation=s3://$GOLD_BUCKET/athena-results/ \
            --query 'QueryExecutionId' \
            --output text)
        
        sleep 3
        
        STATUS=$(aws athena get-query-execution \
            --query-execution-id $EXEC_ID \
            --query 'QueryExecution.Status.State' \
            --output text)
        
        if [ "$STATUS" = "SUCCEEDED" ]; then
            echo "  ✅ $table partitions repaired"
        else
            echo "  ⚠️  $table repair status: $STATUS"
        fi
    done
    
    echo ""
}

# Function to verify results
verify_results() {
    echo "Step 5: Verifying Results..."
    echo "=============================="
    
    echo "Running test query on daily_sales_summary..."
    
    QUERY="SELECT 
        COUNT(*) as total_days,
        MIN(order_date) as earliest_date,
        MAX(order_date) as latest_date,
        SUM(total_revenue) as total_revenue,
        SUM(total_orders) as total_orders
    FROM daily_sales_summary"
    
    EXEC_ID=$(aws athena start-query-execution \
        --query-string "$QUERY" \
        --query-execution-context Database=$GLUE_DATABASE \
        --result-configuration OutputLocation=s3://$GOLD_BUCKET/athena-results/ \
        --query 'QueryExecutionId' \
        --output text)
    
    echo "Query ID: $EXEC_ID"
    echo "Waiting for results..."
    sleep 5
    
    aws athena get-query-results --query-execution-id $EXEC_ID --output table
    
    echo ""
    echo "✅ Verification complete!"
    echo ""
}

# Main execution
case "$1" in
    generate)
        generate_data
        ;;
    upload)
        upload_to_s3
        ;;
    transform)
        run_transformations
        ;;
    repair)
        repair_partitions
        ;;
    verify)
        verify_results
        ;;
    all)
        generate_data
        upload_to_s3
        run_transformations
        repair_partitions
        verify_results
        ;;
    *)
        echo "Usage: $0 {generate|upload|transform|repair|verify|all}"
        echo ""
        echo "Commands:"
        echo "  generate   - Generate sample data locally"
        echo "  upload     - Upload data to S3 Bronze layer"
        echo "  transform  - Run Bronze→Silver→Gold transformations"
        echo "  repair     - Repair Athena partitions"
        echo "  verify     - Run test query to verify data"
        echo "  all        - Run all steps above"
        echo ""
        echo "Quick fix: $0 all"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "Done!"
echo "========================================"