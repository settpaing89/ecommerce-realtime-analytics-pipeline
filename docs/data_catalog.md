# Data Catalog Documentation

## Database: ecommerce_analytics_dev

### Tables

#### 1. customers
**Location:** s3://BUCKET/customers/
**Format:** Parquet
**Partitions:** year, month, day
**Rows:** ~1,000

| Column | Type | Description |
|--------|------|-------------|
| customer_id | string | Unique customer identifier |
| first_name | string | Customer first name |
| last_name | string | Customer last name |
| email | string | Customer email |
| phone | string | Phone number |
| city | string | City |
| state | string | State |
| signup_date | timestamp | Account creation date |
| customer_segment | string | Premium/Regular/New |
| is_active | boolean | Account active status |

#### 2. products
**Location:** s3://BUCKET/products/
**Format:** Parquet
**Partitions:** year, month, day
**Rows:** ~100

| Column | Type | Description |
|--------|------|-------------|
| product_id | string | Unique product identifier |
| product_name | string | Product name |
| category | string | Product category |
| brand | string | Brand name |
| base_price | double | Base price |
| current_price | double | Current selling price |
| inventory_quantity | int | Available inventory |
| rating | double | Average rating (1-5) |
| is_active | boolean | Product active status |

#### 3. orders
**Location:** s3://BUCKET/orders/
**Format:** Parquet
**Partitions:** year, month, day
**Rows:** ~10,000

| Column | Type | Description |
|--------|------|-------------|
| order_id | string | Unique order identifier |
| customer_id | string | FK to customers |
| product_id | string | FK to products |
| order_date | timestamp | Order placement date |
| quantity | int | Quantity ordered |
| unit_price | double | Price per unit |
| subtotal | double | Subtotal before tax/shipping |
| tax | double | Tax amount |
| shipping_cost | double | Shipping cost |
| total_amount | double | Total order amount |
| payment_method | string | Payment method used |
| status | string | Order status |

#### 4. events
**Location:** s3://BUCKET/events/
**Format:** Parquet
**Partitions:** year, month, day
**Rows:** ~20,000

| Column | Type | Description |
|--------|------|-------------|
| event_id | string | Unique event identifier |
| customer_id | string | FK to customers (nullable) |
| session_id | string | User session ID |
| event_type | string | Type of event |
| product_id | string | Related product (nullable) |
| event_timestamp | timestamp | When event occurred |
| device_type | string | Device used |
| browser | string | Browser used |

## Sample Queries

### Business Metrics
```sql
-- Total revenue
SELECT SUM(total_amount) as total_revenue FROM orders;

-- Average order value
SELECT AVG(total_amount) as avg_order_value FROM orders;

-- Conversion rate (orders / events)
SELECT 
    (SELECT COUNT(*) FROM orders) * 100.0 / 
    (SELECT COUNT(*) FROM events WHERE event_type = 'page_view') 
    as conversion_rate;
```

### Customer Analysis
```sql
-- Top customers by revenue
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) as num_orders,
    SUM(o.total_amount) as lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY lifetime_value DESC
LIMIT 10;
```

### Product Performance
```sql
-- Best selling products
SELECT 
    p.product_name,
    p.category,
    COUNT(o.order_id) as times_sold,
    SUM(o.quantity) as units_sold,
    SUM(o.total_amount) as revenue
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;
```
