-- Business Analytics Queries

-- ============================================
-- Revenue Analytics
-- ============================================

-- 1. Revenue Trend (Last 30 Days)
SELECT 
    order_date,
    total_revenue,
    total_orders,
    avg_order_value,
    SUM(total_revenue) OVER (
        ORDER BY order_date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) as rolling_30day_revenue
FROM daily_sales_summary
WHERE order_date >= CURRENT_DATE - INTERVAL '30' DAY
ORDER BY order_date DESC;

-- 2. Month-over-Month Growth
WITH monthly_sales AS (
    SELECT 
        year,
        month,
        SUM(total_revenue) as month_revenue,
        SUM(total_orders) as month_orders
    FROM daily_sales_summary
    GROUP BY year, month
)
SELECT 
    year,
    month,
    month_revenue,
    LAG(month_revenue) OVER (ORDER BY year, month) as prev_month_revenue,
    ROUND(
        (month_revenue - LAG(month_revenue) OVER (ORDER BY year, month)) / 
        LAG(month_revenue) OVER (ORDER BY year, month) * 100,
        2
    ) as revenue_growth_pct
FROM monthly_sales
ORDER BY year DESC, month DESC;

-- ============================================
-- Customer Analytics
-- ============================================

-- 3. Customer Segmentation
SELECT 
    segment,
    COUNT(*) as customer_count,
    ROUND(AVG(lifetime_value), 2) as avg_ltv,
    ROUND(AVG(total_orders), 2) as avg_orders,
    ROUND(AVG(days_as_customer), 0) as avg_customer_age_days
FROM customer_lifetime_value
GROUP BY segment
ORDER BY avg_ltv DESC;

-- 4. Top 100 Customers by Lifetime Value
SELECT 
    customer_id,
    lifetime_value,
    total_orders,
    avg_order_value,
    days_since_last_order,
    segment,
    CASE 
        WHEN days_since_last_order <= 30 THEN 'Active'
        WHEN days_since_last_order <= 90 THEN 'At Risk'
        ELSE 'Inactive'
    END as status
FROM customer_lifetime_value
ORDER BY lifetime_value DESC
LIMIT 100;

-- 5. Customer Retention
SELECT 
    CASE 
        WHEN days_since_last_order <= 7 THEN '0-7 days'
        WHEN days_since_last_order <= 30 THEN '8-30 days'
        WHEN days_since_last_order <= 90 THEN '31-90 days'
        ELSE '90+ days'
    END as recency_bucket,
    COUNT(*) as customer_count,
    ROUND(AVG(lifetime_value), 2) as avg_ltv
FROM customer_lifetime_value
GROUP BY 1
ORDER BY 1;

-- ============================================
-- Product Analytics
-- ============================================

-- 6. Top 20 Products by Revenue
SELECT 
    product_name,
    category,
    total_revenue,
    units_sold,
    times_ordered,
    profit_margin,
    revenue_rank
FROM product_performance
ORDER BY total_revenue DESC
LIMIT 20;

-- 7. Product Performance by Category
SELECT 
    category,
    COUNT(DISTINCT product_id) as num_products,
    SUM(total_revenue) as category_revenue,
    SUM(units_sold) as category_units_sold,
    ROUND(AVG(profit_margin), 2) as avg_profit_margin
FROM product_performance
GROUP BY category
ORDER BY category_revenue DESC;

-- 8. Slow-Moving Products
SELECT 
    product_name,
    category,
    times_ordered,
    total_revenue,
    profit_margin
FROM product_performance
WHERE times_ordered < 5
  AND total_revenue < 100
ORDER BY times_ordered ASC, total_revenue ASC
LIMIT 50;

-- ============================================
-- Conversion Analytics
-- ============================================

-- 9. Conversion Funnel
SELECT 
    event_type,
    total_events,
    unique_sessions,
    session_conversion_rate,
    LAG(session_conversion_rate) OVER (ORDER BY stage_order) as prev_stage_rate,
    ROUND(
        session_conversion_rate / LAG(session_conversion_rate) OVER (ORDER BY stage_order) * 100,
        2
    ) as stage_conversion_rate
FROM conversion_funnel
ORDER BY stage_order;

-- ============================================
-- Executive Summary
-- ============================================

-- 10. Key Business Metrics (Last 30 Days)
WITH last_30_days AS (
    SELECT 
        SUM(total_revenue) as revenue_30d,
        SUM(total_orders) as orders_30d,
        AVG(avg_order_value) as avg_order_value_30d,
        SUM(unique_customers) as unique_customers_30d
    FROM daily_sales_summary
    WHERE order_date >= CURRENT_DATE - INTERVAL '30' DAY
),
previous_30_days AS (
    SELECT 
        SUM(total_revenue) as revenue_prev_30d,
        SUM(total_orders) as orders_prev_30d
    FROM daily_sales_summary
    WHERE order_date >= CURRENT_DATE - INTERVAL '60' DAY
      AND order_date < CURRENT_DATE - INTERVAL '30' DAY
)
SELECT 
    ROUND(l.revenue_30d, 2) as revenue_last_30_days,
    ROUND(p.revenue_prev_30d, 2) as revenue_previous_30_days,
    ROUND((l.revenue_30d - p.revenue_prev_30d) / p.revenue_prev_30d * 100, 2) as revenue_growth_pct,
    l.orders_30d as orders_last_30_days,
    ROUND(l.avg_order_value_30d, 2) as avg_order_value,
    l.unique_customers_30d as unique_customers
FROM last_30_days l, previous_30_days p;
