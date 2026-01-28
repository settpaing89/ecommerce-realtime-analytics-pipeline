# Data Catalog Documentation

Complete reference for all datasets, schemas, and sample queries.

---

## 📊 Database Overview

**Database:** `ecommerce_analytics_dev`  
**Location:** AWS Glue Data Catalog  
**Total Tables:** 4  
**Total Records:** 31,100  
**Storage Format:** Apache Parquet (Snappy compression)  
**Partitioning:** year/month/day

---

## 📋 Tables

### 1. customers

**Purpose:** Customer profiles and demographics

**Location:** `s3://bronze-bucket/customers/year=YYYY/month=MM/day=DD/`  
**Rows:** ~1,000  
**Size:** ~180 KB  
**Update Frequency:** Daily

#### Schema

| Column | Type | Nullable | Description | Example |
|--------|------|----------|-------------|---------|
| `customer_id` | string | No | Unique identifier | `CUST-000001` |
| `first_name` | string | No | Customer first name | `John` |
| `last_name` | string | No | Customer last name | `Smith` |
| `email` | string | No | Email address | `john.smith@email.com` |
| `phone` | string | No | Phone number | `555-0123` |
| `date_of_birth` | date | No | Birth date | `1985-03-15` |
| `gender` | string | No | Gender | `M`, `F`, `Other` |
| `city` | string | No | City | `New York` |
| `state` | string | No | State | `NY` |
| `country` | string | No | Country | `USA` |
| `postal_code` | string | No | ZIP code | `10001` |
| `signup_date` | timestamp | No | Account creation date | `2023-06-15 14:30:00` |
| `customer_segment` | string | No | Segment | `Premium`, `Regular`, `New` |
| `is_active` | boolean | No | Active status | `true`, `false` |

#### Sample Query

```sql
-- Active premium customers by state
SELECT 
    state,
    COUNT(*) as premium_customers,
    AVG(EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM date_of_birth)) as avg_age
FROM customers
WHERE is_active = true 
  AND customer_segment = 'Premium'
GROUP BY state
ORDER BY premium_customers DESC
LIMIT 10;
```

#### Data Quality Rules

```
✓ customer_id: Unique, format "CUST-NNNNNN"
✓ email: Valid format, lowercase
✓ signup_date: Not in future
✓ is_active: 75% true, 25% false
✓ No null values allowed
```

---

### 2. products

**Purpose:** Product catalog with pricing and inventory

**Location:** `s3://bronze-bucket/products/year=YYYY/month=MM/day=DD/`  
**Rows:** ~100  
**Size:** ~20 KB  
**Update Frequency:** Daily

#### Schema

| Column | Type | Nullable | Description | Example |
|--------|------|----------|-------------|---------|
| `product_id` | string | No | Unique identifier | `PROD-0001` |
| `product_name` | string | No | Product name | `Wireless Mouse` |
| `category` | string | No | Product category | `Electronics` |
| `subcategory` | string | No | Subcategory | `Electronics - Type A` |
| `brand` | string | No | Brand name | `TechCorp` |
| `base_price` | double | No | Original price | `49.99` |
| `current_price` | double | No | Current selling price | `39.99` |
| `cost` | double | No | Cost to business | `25.00` |
| `inventory_quantity` | int | No | Stock level | `450` |
| `weight_kg` | double | No | Weight in kg | `0.15` |
| `rating` | double | No | Average rating (1-5) | `4.5` |
| `num_reviews` | int | No | Number of reviews | `127` |
| `is_active` | boolean | No | Available for sale | `true` |
| `created_date` | timestamp | No | First listed date | `2022-03-10 09:00:00` |

#### Categories

```
Electronics        (12 products)
Clothing           (15 products)
Home & Kitchen     (18 products)
Books              (10 products)
Toys & Games       (14 products)
Sports             (11 products)
Beauty             (13 products)
Grocery            (7 products)
```

#### Sample Query

```sql
-- Low stock alert by category
SELECT 
    category,
    product_name,
    inventory_quantity,
    current_price * inventory_quantity as inventory_value
FROM products
WHERE inventory_quantity < 50
  AND is_active = true
ORDER BY inventory_quantity ASC;
```

#### Data Quality Rules

```
✓ product_id: Unique, format "PROD-NNNN"
✓ current_price >= cost
✓ inventory_quantity >= 0
✓ rating: Between 3.0 and 5.0
✓ is_active: 75% true
```

---

### 3. orders

**Purpose:** Transaction records

**Location:** `s3://bronze-bucket/orders/year=YYYY/month=MM/day=DD/`  
**Rows:** ~10,000  
**Size:** ~1.5 MB  
**Update Frequency:** Continuous (real-time)

#### Schema

| Column | Type | Nullable | Description | Example |
|--------|------|----------|-------------|---------|
| `order_id` | string | No | Unique identifier | `ORD-00000001` |
| `customer_id` | string | No | FK to customers | `CUST-000123` |
| `product_id` | string | No | FK to products | `PROD-0045` |
| `order_date` | timestamp | No | Order timestamp | `2025-01-27 10:30:45` |
| `quantity` | int | No | Quantity ordered | `2` |
| `unit_price` | double | No | Price per unit | `49.99` |
| `subtotal` | double | No | Before tax/shipping | `99.98` |
| `tax` | double | No | Tax amount (8%) | `8.00` |
| `shipping_cost` | double | No | Shipping fee | `5.99` |
| `total_amount` | double | No | Final total | `113.97` |
| `payment_method` | string | No | Payment type | `credit_card` |
| `status` | string | No | Order status | `delivered` |
| `shipping_address` | string | No | Delivery address | `123 Main St...` |
| `billing_address` | string | No | Billing address | `123 Main St...` |
| `created_at` | timestamp | No | Record created | `2025-01-27 10:30:45` |
| `updated_at` | timestamp | No | Last updated | `2025-01-29 14:20:00` |

#### Status Values

```
pending     → Order placed, payment processing
confirmed   → Payment confirmed, preparing shipment
shipped     → In transit
delivered   → Successfully delivered (78%)
cancelled   → Order cancelled
```

#### Sample Queries

```sql
-- Daily sales summary
SELECT 
    DATE(order_date) as order_day,
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(total_amount) as revenue,
    AVG(total_amount) as avg_order_value
FROM orders
WHERE status != 'cancelled'
GROUP BY DATE(order_date)
ORDER BY order_day DESC
LIMIT 30;

-- Revenue by payment method
SELECT 
    payment_method,
    COUNT(*) as num_orders,
    SUM(total_amount) as revenue,
    AVG(total_amount) as avg_order_value
FROM orders
WHERE status = 'delivered'
GROUP BY payment_method
ORDER BY revenue DESC;

-- Customer repeat purchase rate
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(*) as order_count
    FROM orders
    WHERE status = 'delivered'
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-time'
        WHEN order_count BETWEEN 2 AND 5 THEN 'Regular'
        ELSE 'Loyal'
    END as customer_type,
    COUNT(*) as num_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM customer_orders
GROUP BY 1;
```

#### Data Quality Rules

```
✓ order_id: Unique, format "ORD-NNNNNNNN"
✓ customer_id: Exists in customers table
✓ product_id: Exists in products table
✓ quantity: > 0
✓ total_amount: = subtotal + tax + shipping_cost
✓ order_date: Not in future
✓ status: Valid enum value
```

---

### 4. events

**Purpose:** Web clickstream and user behavior tracking

**Location:** `s3://bronze-bucket/events/year=YYYY/month=MM/day=DD/`  
**Rows:** ~20,000  
**Size:** ~2.3 MB  
**Update Frequency:** Real-time

#### Schema

| Column | Type | Nullable | Description | Example |
|--------|------|----------|-------------|---------|
| `event_id` | string | No | Unique identifier | `EVT-00000001` |
| `customer_id` | string | **Yes** | FK to customers (null if anonymous) | `CUST-000123` |
| `session_id` | string | No | User session ID | `550e8400-e29b-41d4-a716...` |
| `event_type` | string | No | Type of event | `page_view` |
| `product_id` | string | **Yes** | Related product (null for non-product events) | `PROD-0045` |
| `event_timestamp` | timestamp | No | When event occurred | `2025-01-27 10:30:45.123` |
| `page_url` | string | No | Page URL | `/products/wireless-mouse` |
| `referrer_url` | string | **Yes** | Referring URL (null for direct traffic) | `https://google.com` |
| `device_type` | string | No | Device used | `mobile`, `desktop`, `tablet` |
| `browser` | string | No | Browser used | `Chrome` |
| `ip_address` | string | No | IP address | `192.168.1.1` |
| `country` | string | No | Country | `USA` |
| `city` | string | No | City | `New York` |

#### Event Types

```
page_view         (41%) → General page visit
product_view      (28%) → Product detail page
add_to_cart       (15%) → Added item to cart
remove_from_cart  (5%)  → Removed item from cart
checkout_start    (6%)  → Initiated checkout
purchase          (5%)  → Completed purchase
```

#### Sample Queries

```sql
-- Conversion funnel analysis
WITH funnel AS (
    SELECT 
        event_type,
        COUNT(DISTINCT session_id) as sessions
    FROM events
    WHERE DATE(event_timestamp) = CURRENT_DATE - INTERVAL '1' DAY
    GROUP BY event_type
)
SELECT 
    event_type,
    sessions,
    ROUND(sessions * 100.0 / FIRST_VALUE(sessions) OVER (ORDER BY 
        CASE event_type
            WHEN 'page_view' THEN 1
            WHEN 'product_view' THEN 2
            WHEN 'add_to_cart' THEN 3
            WHEN 'checkout_start' THEN 4
            WHEN 'purchase' THEN 5
        END
    ), 2) as conversion_rate
FROM funnel
ORDER BY conversion_rate DESC;

-- Top traffic sources
SELECT 
    CASE 
        WHEN referrer_url IS NULL THEN 'Direct'
        WHEN referrer_url LIKE '%google%' THEN 'Google'
        WHEN referrer_url LIKE '%facebook%' THEN 'Facebook'
        ELSE 'Other'
    END as traffic_source,
    COUNT(*) as visits,
    COUNT(DISTINCT session_id) as unique_sessions
FROM events
WHERE event_type = 'page_view'
GROUP BY 1
ORDER BY visits DESC;

-- Device breakdown
SELECT 
    device_type,
    browser,
    COUNT(*) as events,
    COUNT(DISTINCT session_id) as sessions,
    AVG(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) * 100 as conversion_rate
FROM events
GROUP BY device_type, browser
ORDER BY events DESC;
```

#### Data Quality Rules

```
✓ event_id: Unique, format "EVT-NNNNNNNN"
✓ customer_id: 20% null (anonymous users) ✓
✓ product_id: 30% null (non-product events) ✓
✓ referrer_url: 50% null (direct traffic) ✓
✓ event_type: Valid enum value
✓ event_timestamp: Not in future
```

---

## 🔗 Table Relationships

```
customers (1) ──────< (N) orders
    │                     │
    │                     │
    └────< (N) events     │
                          │
products (1) ─────────────┘
    │
    └────< (N) events
```

**Referential Integrity:**
- `orders.customer_id` → `customers.customer_id`
- `orders.product_id` → `products.product_id`
- `events.customer_id` → `customers.customer_id` (nullable)
- `events.product_id` → `products.product_id` (nullable)

---

## 📈 Common Analytics Queries

### Revenue Analytics

```sql
-- Total revenue by product category
SELECT 
    p.category,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.quantity) as units_sold,
    SUM(o.total_amount) as revenue,
    AVG(o.total_amount) as avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.status = 'delivered'
  AND o.order_date >= CURRENT_DATE - INTERVAL '30' DAY
GROUP BY p.category
ORDER BY revenue DESC;
```

### Customer Analytics

```sql
-- Customer lifetime value (CLV)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.customer_segment,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as lifetime_value,
    AVG(o.total_amount) as avg_order_value,
    MIN(o.order_date) as first_order,
    MAX(o.order_date) as last_order,
    DATE_DIFF('day', MAX(o.order_date), CURRENT_DATE) as days_since_last_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'delivered'
GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_segment
HAVING COUNT(o.order_id) > 0
ORDER BY lifetime_value DESC
LIMIT 100;
```

### Product Performance

```sql
-- Best and worst performing products
WITH product_metrics AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        COUNT(o.order_id) as times_ordered,
        SUM(o.quantity) as units_sold,
        SUM(o.total_amount) as revenue,
        (p.current_price - p.cost) * SUM(o.quantity) as profit
    FROM products p
    LEFT JOIN orders o ON p.product_id = o.product_id 
        AND o.status = 'delivered'
        AND o.order_date >= CURRENT_DATE - INTERVAL '30' DAY
    GROUP BY p.product_id, p.product_name, p.category, p.current_price, p.cost
)
SELECT 
    'Top 10' as category,
    product_name,
    revenue,
    profit
FROM product_metrics
ORDER BY revenue DESC
LIMIT 10

UNION ALL

SELECT 
    'Bottom 10',
    product_name,
    revenue,
    profit
FROM product_metrics
ORDER BY revenue ASC
LIMIT 10;
```

### Web Analytics

```sql
-- Session analysis
WITH sessions AS (
    SELECT 
        session_id,
        MIN(event_timestamp) as session_start,
        MAX(event_timestamp) as session_end,
        COUNT(*) as event_count,
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN 1 END) as page_views,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) as converted
    FROM events
    WHERE DATE(event_timestamp) = CURRENT_DATE - INTERVAL '1' DAY
    GROUP BY session_id
)
SELECT 
    COUNT(*) as total_sessions,
    AVG(event_count) as avg_events_per_session,
    AVG(EXTRACT(EPOCH FROM (session_end - session_start))) / 60 as avg_session_minutes,
    SUM(converted) as conversions,
    ROUND(SUM(converted) * 100.0 / COUNT(*), 2) as conversion_rate
FROM sessions;
```

---

## 🎯 Data Quality Monitoring

### Automated Checks

```sql
-- Run daily data quality checks

-- Check 1: No future dates
SELECT COUNT(*) as future_orders
FROM orders
WHERE order_date > CURRENT_TIMESTAMP;
-- Expected: 0

-- Check 2: Referential integrity
SELECT COUNT(*) as orphaned_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- Expected: 0

-- Check 3: Price consistency
SELECT COUNT(*) as price_errors
FROM orders
WHERE total_amount != subtotal + tax + shipping_cost;
-- Expected: 0

-- Check 4: Daily record count
SELECT 
    DATE(order_date) as order_day,
    COUNT(*) as record_count
FROM orders
WHERE DATE(order_date) >= CURRENT_DATE - INTERVAL '7' DAY
GROUP BY DATE(order_date)
HAVING COUNT(*) < 100;  -- Alert if < 100 orders/day
```

---

## 📚 Metadata

| Table | Created | Last Updated | Owner |
|-------|---------|--------------|-------|
| customers | 2025-01-27 | 2025-01-27 | data-engineering |
| products | 2025-01-27 | 2025-01-27 | data-engineering |
| orders | 2025-01-27 | 2025-01-27 | data-engineering |
| events | 2025-01-27 | 2025-01-27 | data-engineering |

**Schema Version:** 1.0  
**Last Schema Change:** 2025-01-27  
**Contact:** your.email@example.com

---

**Need help with queries?** See [Setup Guide](setup_guide.md) or [Troubleshooting](troubleshooting.md)