"""
Silver to Gold Transformation
Creates aggregated analytics tables
"""

import pandas as pd
import boto3
from datetime import datetime
import os
from io import BytesIO

# AWS clients
s3 = boto3.client('s3')

# Environment variables
SILVER_BUCKET = os.getenv('SILVER_BUCKET', 'ecommerce-analytics-dev-silver')
GOLD_BUCKET = os.getenv('GOLD_BUCKET', 'ecommerce-analytics-dev-gold')

def create_daily_sales_summary(orders_df):
    """Aggregate daily sales metrics"""
    print("Creating daily sales summary...")
    
    summary = orders_df.groupby(orders_df['order_date'].dt.date).agg({
        'order_id': 'count',
        'customer_id': 'nunique',
        'total_amount': ['sum', 'mean'],
        'quantity': 'sum'
    }).reset_index()
    
    summary.columns = [
        'order_date',
        'total_orders',
        'unique_customers',
        'total_revenue',
        'avg_order_value',
        'total_units_sold'
    ]
    
    summary['avg_units_per_order'] = (summary['total_units_sold'] / summary['total_orders']).round(2)
    
    print(f"✓ Created {len(summary)} daily summaries")
    return summary

def create_customer_ltv(orders_df):
    """Calculate customer lifetime value"""
    print("Calculating customer lifetime value...")
    
    ltv = orders_df.groupby('customer_id').agg({
        'order_id': 'count',
        'total_amount': 'sum',
        'order_date': ['min', 'max']
    }).reset_index()
    
    ltv.columns = [
        'customer_id',
        'total_orders',
        'lifetime_value',
        'first_order_date',
        'last_order_date'
    ]
    
    ltv['avg_order_value'] = (ltv['lifetime_value'] / ltv['total_orders']).round(2)
    ltv['days_as_customer'] = (ltv['last_order_date'] - ltv['first_order_date']).dt.days
    ltv['days_since_last_order'] = (datetime.now() - ltv['last_order_date']).dt.days
    
    # Segment customers
    ltv['segment'] = pd.cut(
        ltv['lifetime_value'],
        bins=[0, 100, 500, 1000, float('inf')],
        labels=['Low', 'Medium', 'High', 'VIP']
    )
    
    print(f"✓ Calculated LTV for {len(ltv)} customers")
    return ltv

def create_product_performance(orders_df, products_df):
    """Aggregate product performance"""
    print("Creating product performance metrics...")
    
    performance = orders_df.groupby('product_id').agg({
        'order_id': 'count',
        'quantity': 'sum',
        'total_amount': 'sum'
    }).reset_index()
    
    performance.columns = [
        'product_id',
        'times_ordered',
        'units_sold',
        'total_revenue'
    ]
    
    # Add product details
    if products_df is not None and len(products_df) > 0:
        cols_to_merge = ['product_id', 'product_name', 'category']
        if 'current_price' in products_df.columns:
            cols_to_merge.append('current_price')
        if 'cost' in products_df.columns:
            cols_to_merge.append('cost')
        
        performance = performance.merge(
            products_df[cols_to_merge],
            on='product_id',
            how='left'
        )
        
        # Calculate profit if cost available
        if 'cost' in performance.columns and 'current_price' in performance.columns:
            performance['total_profit'] = (
                (performance['current_price'] - performance['cost']) * performance['units_sold']
            ).round(2)
            performance['profit_margin'] = (
                (performance['current_price'] - performance['cost']) / performance['current_price'] * 100
            ).round(2)
    
    performance['avg_revenue_per_order'] = (
        performance['total_revenue'] / performance['times_ordered']
    ).round(2)
    
    performance['revenue_rank'] = performance['total_revenue'].rank(ascending=False)
    
    print(f"✓ Analyzed {len(performance)} products")
    return performance

def write_to_gold(df, table_name):
    """Write dataframe to gold layer"""
    now = datetime.now()
    key = (
        f"{table_name}/"
        f"year={now.year}/"
        f"month={now.month:02d}/"
        f"{table_name}_{now.strftime('%Y%m%d')}.parquet"
    )
    
    print(f"Writing to s3://{GOLD_BUCKET}/{key}")
    
    # Write to BytesIO buffer
    buffer = BytesIO()
    df.to_parquet(buffer, index=False, compression='snappy')
    buffer.seek(0)
    
    s3.put_object(
        Bucket=GOLD_BUCKET,
        Key=key,
        Body=buffer.getvalue()
    )
    
    print(f"✓ Wrote {len(df)} records to gold layer")

def get_latest_file(prefix):
    """Get most recent file from S3"""
    response = s3.list_objects_v2(Bucket=SILVER_BUCKET, Prefix=prefix)
    if 'Contents' not in response:
        return None
    files = sorted(response['Contents'], key=lambda x: x['LastModified'], reverse=True)
    return files[0]['Key']

def main():
    """Main aggregation function"""
    print("="*60)
    print("Silver → Gold Transformation")
    print("="*60)
    
    try:
        print("\nLoading silver layer data...")
        
        # Load orders
        orders_key = get_latest_file('orders_clean/')
        if orders_key:
            response = s3.get_object(Bucket=SILVER_BUCKET, Key=orders_key)
            buffer = BytesIO(response['Body'].read())
            orders_df = pd.read_parquet(buffer)
            print(f"✓ Loaded {len(orders_df)} orders")
        else:
            print("❌ No orders found in silver layer")
            return
        
        # Load products (optional)
        products_key = get_latest_file('products_clean/')
        products_df = None
        if products_key:
            response = s3.get_object(Bucket=SILVER_BUCKET, Key=products_key)
            buffer = BytesIO(response['Body'].read())
            products_df = pd.read_parquet(buffer)
            print(f"✓ Loaded {len(products_df)} products")
        
        # Create aggregations
        print("\n" + "="*60)
        print("Creating Aggregations")
        print("="*60 + "\n")
        
        # Daily sales
        daily_sales = create_daily_sales_summary(orders_df)
        write_to_gold(daily_sales, 'daily_sales_summary')
        
        # Customer LTV
        customer_ltv = create_customer_ltv(orders_df)
        write_to_gold(customer_ltv, 'customer_lifetime_value')
        
        # Product performance
        product_perf = create_product_performance(orders_df, products_df)
        write_to_gold(product_perf, 'product_performance')
        
        print("\n" + "="*60)
        print("✅ Silver → Gold transformation complete!")
        print("="*60)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
