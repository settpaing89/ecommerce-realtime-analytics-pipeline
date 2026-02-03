-- =================================================================================================
-- Advanced SQL Analytics Library
-- =================================================================================================
-- Run these queries in the AWS Athena Console after creating the tables.
-- =================================================================================================

-- 1. Customer Retention Cohorts
-- Calculate how many customers returned to make a purchase in subsequent months
WITH first_orders AS (
    SELECT 
        customer_id,
        MIN(date_trunc('month', order_date)) as cohort_month
    FROM ecommerce_analytics.orders_silver
    GROUP BY 1
),
customer_activities AS (
    SELECT 
        o.customer_id,
        date_trunc('month', o.order_date) as activity_month
    FROM ecommerce_analytics.orders_silver o
    GROUP BY 1, 2
)
SELECT 
    f.cohort_month,
    date_diff('month', f.cohort_month, a.activity_month) as month_number,
    COUNT(DISTINCT f.customer_id) as users
FROM first_orders f
JOIN customer_activities a ON f.customer_id = a.customer_id
WHERE a.activity_month >= f.cohort_month
GROUP BY 1, 2
ORDER BY 1, 2;

-- 2. Conversion Funnel Analysis
-- Analyze drop-off rates from unique visitors to purchasers
SELECT 
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN session_id END) as visitors,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN session_id END) as cart_adders,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN session_id END) as checkouts,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN session_id END) as purchasers,
    CAST(COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN session_id END) AS DOUBLE) / 
    CAST(COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN session_id END) AS DOUBLE) * 100 as conversion_rate
FROM ecommerce_analytics.events_silver;

-- 3. Moving Average Revenue (7-Day)
-- Smooth out daily volatility to see trends
SELECT 
    order_date,
    total_revenue,
    AVG(total_revenue) OVER (
        ORDER BY order_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as revenue_7day_moving_avg
FROM ecommerce_analytics.daily_sales_summary
WHERE order_date >= date_add('day', -90, current_date)
ORDER BY order_date DESC;

-- 4. High-Value Customer Segmentation
-- Identify customers with high LTV and recent activity
SELECT 
    customer_id,
    segment,
    lifetime_value,
    days_since_last_order
FROM ecommerce_analytics.customer_lifetime_value
WHERE segment IN ('High', 'VIP')
  AND days_since_last_order <= 30
ORDER BY lifetime_value DESC;
