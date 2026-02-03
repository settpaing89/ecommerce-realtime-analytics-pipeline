"""
Bronze to Silver Transformation
Cleans and validates raw data
"""

import pandas as pd
import boto3
from datetime import datetime
import os
import sys
from io import BytesIO

# AWS clients
s3 = boto3.client('s3')

# Environment variables
BRONZE_BUCKET = os.getenv('BRONZE_BUCKET', 'ecommerce-analytics-dev-bronze')
SILVER_BUCKET = os.getenv('SILVER_BUCKET', 'ecommerce-analytics-dev-silver')

def transform_customers(df):
    """Transform customer data"""
    print(f"Transforming {len(df)} customer records...")
    
    # Remove duplicates
    df = df.drop_duplicates(subset=['customer_id'], keep='last')
    
    # Standardize email
    if 'email' in df.columns:
        df['email'] = df['email'].str.lower().str.strip()
    
    # Standardize phone
    if 'phone' in df.columns:
        df['phone'] = df['phone'].astype(str).str.replace(r'[^0-9]', '', regex=True)
    
    # Calculate age
    if 'date_of_birth' in df.columns:
        df['date_of_birth'] = pd.to_datetime(df['date_of_birth'], errors='coerce')
        df['age'] = ((datetime.now() - df['date_of_birth']).dt.days // 365).fillna(0).astype(int)
    
    # Data quality flags
    df['dq_email_valid'] = df['email'].str.contains('@', na=False) if 'email' in df.columns else False
    df['dq_has_phone'] = df['phone'].notna() if 'phone' in df.columns else False
    
    print(f"✓ Cleaned to {len(df)} unique customers")
    return df

def transform_products(df):
    """Transform product data"""
    print(f"Transforming {len(df)} product records...")
    
    # Remove duplicates
    df = df.drop_duplicates(subset=['product_id'], keep='last')
    
    # Ensure positive prices
    if 'base_price' in df.columns:
        df = df[df['base_price'] > 0]
    if 'current_price' in df.columns:
        df = df[df['current_price'] > 0]
    
    # Calculate discount
    if 'base_price' in df.columns and 'current_price' in df.columns:
        df['discount_pct'] = ((df['base_price'] - df['current_price']) / df['base_price'] * 100).round(2)
    
    # Calculate profit margin
    if 'current_price' in df.columns and 'cost' in df.columns:
        df['profit_margin'] = ((df['current_price'] - df['cost']) / df['current_price'] * 100).round(2)
    
    # Data quality
    df['dq_has_inventory'] = df['inventory_quantity'] > 0 if 'inventory_quantity' in df.columns else False
    
    print(f"✓ Cleaned to {len(df)} unique products")
    return df

def transform_orders(df):
    """Transform order data"""
    print(f"Transforming {len(df)} order records...")
    
    # Remove duplicates
    df = df.drop_duplicates(subset=['order_id'], keep='last')
    
    # Ensure positive amounts
    if 'total_amount' in df.columns:
        df = df[df['total_amount'] > 0]
    if 'quantity' in df.columns:
        df = df[df['quantity'] > 0]
    
    # Parse dates
    if 'order_date' in df.columns:
        df['order_date'] = pd.to_datetime(df['order_date'], errors='coerce')
        
        # Extract components
        df['order_year'] = df['order_date'].dt.year
        df['order_month'] = df['order_date'].dt.month
        df['order_day'] = df['order_date'].dt.day
        df['order_dayofweek'] = df['order_date'].dt.dayofweek
        df['order_hour'] = df['order_date'].dt.hour
    
    # Calculate unit price if missing
    if 'unit_price' not in df.columns and 'subtotal' in df.columns and 'quantity' in df.columns:
        df['unit_price'] = (df['subtotal'] / df['quantity']).round(2)
    
    # Data quality
    df['dq_has_customer'] = df['customer_id'].notna()
    df['dq_has_product'] = df['product_id'].notna()
    df['dq_valid_status'] = df['status'].isin(['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'])
    
    print(f"✓ Cleaned to {len(df)} valid orders")
    return df

def transform_events(df):
    """Transform event data"""
    print(f"Transforming {len(df)} event records...")
    
    # Remove duplicates
    df = df.drop_duplicates(subset=['event_id'], keep='last')
    
    # Parse timestamp
    if 'event_timestamp' in df.columns:
        df['event_timestamp'] = pd.to_datetime(df['event_timestamp'], errors='coerce')
        
        # Extract components
        df['event_date'] = df['event_timestamp'].dt.date
        df['event_hour'] = df['event_timestamp'].dt.hour
        df['event_dayofweek'] = df['event_timestamp'].dt.dayofweek
    
    # Categorize
    df['is_anonymous'] = df['customer_id'].isna()
    
    # Data quality
    df['dq_has_session'] = df['session_id'].notna()
    df['dq_valid_event_type'] = df['event_type'].isin([
        'page_view', 'product_view', 'add_to_cart', 
        'remove_from_cart', 'checkout_start', 'purchase'
    ])
    
    print(f"✓ Cleaned to {len(df)} valid events")
    return df

def process_data_type(data_type, bronze_key):
    """Process one data type"""
    print(f"\n{'='*60}")
    print(f"Processing: {data_type}")
    print(f"{'='*60}")
    
    try:
        # Download from bronze - FIX: Use BytesIO
        print(f"Downloading from s3://{BRONZE_BUCKET}/{bronze_key}")
        response = s3.get_object(Bucket=BRONZE_BUCKET, Key=bronze_key)
        
        # Read into BytesIO buffer first
        buffer = BytesIO(response['Body'].read())
        df = pd.read_parquet(buffer)
        
        print(f"Loaded {len(df)} records")
        
        # Transform based on type
        if data_type == 'customers':
            df_clean = transform_customers(df)
        elif data_type == 'products':
            df_clean = transform_products(df)
        elif data_type == 'orders':
            df_clean = transform_orders(df)
        elif data_type == 'events':
            df_clean = transform_events(df)
        else:
            print(f"Unknown data type: {data_type}")
            return
        
        # Write to silver
        now = datetime.now()
        silver_key = (
            f"{data_type}_clean/"
            f"year={now.year}/"
            f"month={now.month:02d}/"
            f"day={now.day:02d}/"
            f"{data_type}_clean_{now.strftime('%Y%m%d_%H%M%S')}.parquet"
        )
        
        print(f"Writing to s3://{SILVER_BUCKET}/{silver_key}")
        
        # Convert to parquet bytes
        parquet_buffer = BytesIO()
        df_clean.to_parquet(parquet_buffer, index=False, compression='snappy')
        parquet_buffer.seek(0)
        
        s3.put_object(
            Bucket=SILVER_BUCKET,
            Key=silver_key,
            Body=parquet_buffer.getvalue()
        )
        
        print(f"✓ Wrote {len(df_clean)} cleaned records to silver layer")
        
        # Print summary
        print(f"\nSummary:")
        print(f"  Input records: {len(df)}")
        print(f"  Output records: {len(df_clean)}")
        print(f"  Records removed: {len(df) - len(df_clean)}")
        print(f"  Quality score: {len(df_clean)/len(df)*100:.1f}%")
        
    except Exception as e:
        print(f"Error processing {data_type}: {e}")
        import traceback
        traceback.print_exc()

def main():
    """Main processing function"""
    print("="*60)
    print("Bronze → Silver Transformation")
    print("="*60)
    
    data_types = ['customers', 'products', 'orders', 'events']
    
    for data_type in data_types:
        try:
            # List files in bronze
            prefix = f"{data_type}/"
            response = s3.list_objects_v2(Bucket=BRONZE_BUCKET, Prefix=prefix)
            
            if 'Contents' not in response:
                print(f"\nNo files found for {data_type}")
                continue
            
            # Get most recent file
            files = sorted(response['Contents'], key=lambda x: x['LastModified'], reverse=True)
            latest_file = files[0]['Key']
            
            # Process it
            process_data_type(data_type, latest_file)
            
        except Exception as e:
            print(f"Error with {data_type}: {e}")
            continue
    
    print("\n" + "="*60)
    print("✅ Bronze → Silver transformation complete!")
    print("="*60)

if __name__ == '__main__':
    main()
