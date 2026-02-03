#!/bin/bash

echo "========================================"
echo "Data Pipeline Full Diagnostic"
echo "========================================"
echo ""

# Get bucket names
export BRONZE_BUCKET=$(cd terraform && terraform output -raw bronze_bucket_name 2>/dev/null)
export SILVER_BUCKET=$(cd terraform && terraform output -raw silver_bucket_name 2>/dev/null)
export GOLD_BUCKET=$(cd terraform && terraform output -raw gold_bucket_name 2>/dev/null)

echo "📦 Checking BRONZE Layer (Raw Data)"
echo "========================================"
echo ""

check_bronze_data() {
    local data_type=$1
    echo "📊 $data_type:"
    
    # Count files
    file_count=$(aws s3 ls s3://$BRONZE_BUCKET/$data_type/ --recursive 2>/dev/null | wc -l)
    
    if [ $file_count -eq 0 ]; then
        echo "  ❌ No files found"
        echo "  → Need to generate and upload $data_type data"
        return 1
    fi
    
    echo "  ✅ $file_count files found"
    
    # Get file sizes
    total_size=$(aws s3 ls s3://$BRONZE_BUCKET/$data_type/ --recursive --summarize 2>/dev/null | grep "Total Size" | awk '{print $3}')
    if [ ! -z "$total_size" ]; then
        size_mb=$(echo "scale=2; $total_size / 1048576" | bc)
        echo "  📏 Total size: ${size_mb} MB"
    fi
    
    # Show latest file
    echo "  Latest files:"
    aws s3 ls s3://$BRONZE_BUCKET/$data_type/ --recursive 2>/dev/null | tail -3 | sed 's/^/    /'
    
    # Download and check row count for one file
    echo "  Checking row count..."
    latest_file=$(aws s3 ls s3://$BRONZE_BUCKET/$data_type/ --recursive 2>/dev/null | tail -1 | awk '{print $4}')
    
    if [ ! -z "$latest_file" ]; then
        # Download file temporarily
        temp_file="/tmp/check_${data_type}.parquet"
        aws s3 cp s3://$BRONZE_BUCKET/$latest_file $temp_file 2>/dev/null
        
        # Check row count with Python
        row_count=$(python3 << EOF
import pandas as pd
try:
    df = pd.read_parquet('$temp_file')
    print(len(df))
except Exception as e:
    print(0)
EOF
)
        echo "  📊 Rows in latest file: $row_count"
        rm -f $temp_file
    fi
    
    echo ""
}

# Check each data type in bronze
check_bronze_data "orders"
check_bronze_data "customers"
check_bronze_data "products"
check_bronze_data "events"

echo ""
echo "🧹 Checking SILVER Layer (Cleaned Data)"
echo "========================================"
echo ""

check_silver_data() {
    local data_type=$1
    echo "📊 ${data_type}_clean:"
    
    file_count=$(aws s3 ls s3://$SILVER_BUCKET/${data_type}_clean/ --recursive 2>/dev/null | wc -l)
    
    if [ $file_count -eq 0 ]; then
        echo "  ❌ No files found"
        echo "  → Run: python src/processing/transform_bronze_to_silver.py"
        return 1
    fi
    
    echo "  ✅ $file_count files found"
    
    # Get latest file and check rows
    latest_file=$(aws s3 ls s3://$SILVER_BUCKET/${data_type}_clean/ --recursive 2>/dev/null | tail -1 | awk '{print $4}')
    
    if [ ! -z "$latest_file" ]; then
        temp_file="/tmp/check_${data_type}_silver.parquet"
        aws s3 cp s3://$SILVER_BUCKET/$latest_file $temp_file 2>/dev/null
        
        row_count=$(python3 << EOF
import pandas as pd
try:
    df = pd.read_parquet('$temp_file')
    print(len(df))
except Exception as e:
    print(0)
EOF
)
        echo "  📊 Rows in latest file: $row_count"
        rm -f $temp_file
    fi
    
    echo "  Latest files:"
    aws s3 ls s3://$SILVER_BUCKET/${data_type}_clean/ --recursive 2>/dev/null | tail -3 | sed 's/^/    /'
    echo ""
}

check_silver_data "orders"
check_silver_data "customers"
check_silver_data "products"
check_silver_data "events"

echo ""
echo "⭐ Checking GOLD Layer (Analytics Tables)"
echo "========================================"
echo ""

check_gold_data() {
    local table=$1
    echo "📊 $table:"
    
    file_count=$(aws s3 ls s3://$GOLD_BUCKET/$table/ --recursive 2>/dev/null | wc -l)
    
    if [ $file_count -eq 0 ]; then
        echo "  ❌ No files found"
        echo "  → Run: python src/processing/transform_silver_to_gold.py"
        return 1
    fi
    
    echo "  ✅ $file_count files found"
    
    # Get latest file and check rows
    latest_file=$(aws s3 ls s3://$GOLD_BUCKET/$table/ --recursive 2>/dev/null | tail -1 | awk '{print $4}')
    
    if [ ! -z "$latest_file" ]; then
        temp_file="/tmp/check_${table}_gold.parquet"
        aws s3 cp s3://$GOLD_BUCKET/$latest_file $temp_file 2>/dev/null
        
        row_count=$(python3 << EOF
import pandas as pd
try:
    df = pd.read_parquet('$temp_file')
    print(len(df))
    print("Columns:", list(df.columns))
    if len(df) > 0:
        print("\nFirst few rows:")
        print(df.head())
except Exception as e:
    print(0)
    print("Error:", str(e))
EOF
)
        echo "  📊 Analysis:"
        echo "$row_count" | sed 's/^/    /'
        rm -f $temp_file
    fi
    
    echo ""
}

check_gold_data "daily_sales_summary"
check_gold_data "customer_lifetime_value"
check_gold_data "product_performance"
check_gold_data "conversion_funnel"

echo ""
echo "========================================"
echo "🔍 Summary & Recommendations"
echo "========================================"
echo ""

# Count rows in bronze
orders_count=$(aws s3 ls s3://$BRONZE_BUCKET/orders/ --recursive 2>/dev/null | wc -l)
customers_count=$(aws s3 ls s3://$BRONZE_BUCKET/customers/ --recursive 2>/dev/null | wc -l)
products_count=$(aws s3 ls s3://$BRONZE_BUCKET/products/ --recursive 2>/dev/null | wc -l)

echo "Data Availability:"
echo "  Bronze Layer:"
echo "    - Orders: $orders_count files"
echo "    - Customers: $customers_count files"
echo "    - Products: $products_count files"
echo ""

if [ $orders_count -lt 2 ]; then
    echo "⚠️  ISSUE: Very little data in Bronze layer"
    echo ""
    echo "🔧 FIX: Generate more data"
    echo "   1. Check if you have data generation scripts:"
    echo "      ls -la src/data_generation/"
    echo ""
    echo "   2. If yes, generate more data:"
    echo "      python src/data_generation/generate_orders.py --count 10000"
    echo "      python src/data_generation/generate_customers.py --count 1000"
    echo "      python src/data_generation/generate_products.py --count 100"
    echo ""
    echo "   3. Upload to Bronze:"
    echo "      aws s3 cp data/orders.parquet s3://$BRONZE_BUCKET/orders/"
    echo "      aws s3 cp data/customers.parquet s3://$BRONZE_BUCKET/customers/"
    echo "      aws s3 cp data/products.parquet s3://$BRONZE_BUCKET/products/"
    echo ""
fi

echo "   4. Re-run transformations:"
echo "      python src/processing/transform_bronze_to_silver.py"
echo "      python src/processing/transform_silver_to_gold.py"
echo ""
echo "   5. Repair Athena partitions:"
echo "      aws athena start-query-execution \\"
echo "        --query-string 'MSCK REPAIR TABLE daily_sales_summary' \\"
echo "        --query-execution-context Database=\$GLUE_DATABASE \\"
echo "        --result-configuration OutputLocation=s3://\$GOLD_BUCKET/athena-results/"
echo ""

echo "Expected Data Volumes:"
echo "  - Orders: 1,000-10,000 rows → 5-30 days of daily_sales_summary"
echo "  - Customers: 100-1,000 rows → customer_lifetime_value"
echo "  - Products: 10-100 rows → product_performance"
echo ""