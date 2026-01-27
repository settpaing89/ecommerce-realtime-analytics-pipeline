
"""
Quick Data Analysis
Generate insights from the generated data
"""

import pandas as pd
from pathlib import Path

def analyze_data():
    # Load data
    data_dir = Path('data/bronze')
    orders = pd.read_parquet(data_dir / 'orders.parquet')
    products = pd.read_parquet(data_dir / 'products.parquet')
    customers = pd.read_parquet(data_dir / 'customers.parquet')
    
    print("="*60)
    print("BUSINESS INSIGHTS")
    print("="*60)
    
    # Revenue metrics
    total_revenue = orders['total_amount'].sum()
    avg_order_value = orders['total_amount'].mean()
    total_orders = len(orders)
    
    print(f"\n📊 Revenue Metrics:")
    print(f"  Total Revenue: ${total_revenue:,.2f}")
    print(f"  Total Orders: {total_orders:,}")
    print(f"  Average Order Value: ${avg_order_value:,.2f}")
    
    # Order status breakdown
    print(f"\n📦 Order Status:")
    status_counts = orders['status'].value_counts()
    for status, count in status_counts.items():
        pct = (count / total_orders) * 100
        print(f"  {status.capitalize()}: {count:,} ({pct:.1f}%)")
    
    # Top products by revenue
    product_revenue = orders.groupby('product_id')['total_amount'].sum().sort_values(ascending=False)
    print(f"\n🏆 Top 5 Products by Revenue:")
    for i, (product_id, revenue) in enumerate(product_revenue.head().items(), 1):
        product_name = products[products['product_id'] == product_id]['product_name'].values[0]
        print(f"  {i}. {product_id}: ${revenue:,.2f}")
    
    # Customer segments
    print(f"\n👥 Customer Segments:")
    segment_counts = customers['customer_segment'].value_counts()
    for segment, count in segment_counts.items():
        pct = (count / len(customers)) * 100
        print(f"  {segment}: {count:,} ({pct:.1f}%)")
    
    # Product categories
    print(f"\n🏷️  Product Categories:")
    category_counts = products['category'].value_counts()
    for category, count in category_counts.items():
        pct = (count / len(products)) * 100
        print(f"  {category}: {count} ({pct:.1f}%)")
    
    print("\n" + "="*60)

if __name__ == '__main__':
    analyze_data()
