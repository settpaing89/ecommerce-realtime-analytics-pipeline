-- Create Athena Tables for Gold Layer

-- Daily Sales Summary
CREATE EXTERNAL TABLE IF NOT EXISTS daily_sales_summary (
    order_date DATE,
    total_orders BIGINT,
    unique_customers BIGINT,
    total_revenue DOUBLE,
    avg_order_value DOUBLE,
    total_units_sold BIGINT,
    avg_units_per_order DOUBLE
)
PARTITIONED BY (
    year INT,
    month INT
)
STORED AS PARQUET
LOCATION 's3://ecommerce-analytics-dev-gold-396913733976/daily_sales_summary/';

-- Customer Lifetime Value
CREATE EXTERNAL TABLE IF NOT EXISTS customer_lifetime_value (
    customer_id STRING,
    total_orders BIGINT,
    lifetime_value DOUBLE,
    first_order_date TIMESTAMP,
    last_order_date TIMESTAMP,
    avg_order_value DOUBLE,
    days_as_customer INT,
    days_since_last_order INT,
    segment STRING
)
PARTITIONED BY (
    year INT,
    month INT
)
STORED AS PARQUET
LOCATION 's3://ecommerce-analytics-dev-gold-396913733976/customer_lifetime_value/';

-- Product Performance
CREATE EXTERNAL TABLE IF NOT EXISTS product_performance (
    product_id STRING,
    times_ordered BIGINT,
    units_sold BIGINT,
    total_revenue DOUBLE,
    product_name STRING,
    category STRING,
    current_price DOUBLE,
    cost DOUBLE,
    total_profit DOUBLE,
    profit_margin DOUBLE,
    avg_revenue_per_order DOUBLE,
    revenue_rank DOUBLE
)
PARTITIONED BY (
    year INT,
    month INT
)
STORED AS PARQUET
LOCATION 's3://ecommerce-analytics-dev-gold-396913733976/product_performance/';

-- Conversion Funnel
CREATE EXTERNAL TABLE IF NOT EXISTS conversion_funnel (
    event_type STRING,
    total_events BIGINT,
    unique_sessions BIGINT,
    session_conversion_rate DOUBLE,
    stage_order INT
)
PARTITIONED BY (
    year INT,
    month INT
)
STORED AS PARQUET
LOCATION 's3://ecommerce-analytics-dev-gold-396913733976/conversion_funnel/';

-- Add partitions
MSCK REPAIR TABLE daily_sales_summary;
MSCK REPAIR TABLE customer_lifetime_value;
MSCK REPAIR TABLE product_performance;
MSCK REPAIR TABLE conversion_funnel;
