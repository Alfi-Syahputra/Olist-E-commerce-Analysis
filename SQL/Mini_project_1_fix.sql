-- Tipe Data tiap table nya

--Table Customers
--customer_id		(varchar)
--customer_unique_id	(varchar)
--customer_zip_code_prefix	(Int)
--customer_city	(varchar)
--customer_state	(varchar)

--Table Sellers
--seller_id	(varchar)
--seller_zip_code_prefix (int)
--seller_city	(varchar)
--seller_state	(varchar)

--Table Order items
--order_id	(varchar)
--order_item_id	(int)
---product_id	(varchar)
--seller_id	(varchar)
--shipping_limit_date	(varchar)
--price	(float)
--freight_value	(float)

--Table Orders
--order_id	(varchar)
--customer_id	(varchar)
--order_status	(varchar)
--order_purchase_timestamp	(varchar)
--order_approved_at	(varchar)
--order_delivered_carrier_date	(varchar)
--order_delivered_customer_date	(varchar)
--order_estimated_delivery_date	(varchar)


--Alter table untuk Primary key
ALTER TABLE olist_customers_dataset 
ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id)

ALTER TABLE olist_sellers_dataset 
ADD CONSTRAINT pk_sellers PRIMARY KEY (seller_id)

ALTER TABLE olist_order_items_dataset 
ADD CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id)

ALTER TABLE olist_orders_dataset
ADD CONSTRAINT pk_orders PRIMARY KEY (order_id)

--Alter table untuk Foreign key
ALTER TABLE olist_order_items_dataset 
ADD CONSTRAINT fk_order_items_seller
FOREIGN KEY (seller_id)
REFERENCES olist_sellers_dataset (seller_id)

ALTER TABLE olist_orders_dataset
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES olist_customers_dataset(customer_id)

ALTER TABLE olist_order_items_dataset
ADD CONSTRAINT fk_order_items_order
FOREIGN KEY (order_id)
REFERENCES olist_orders_dataset(order_id)


--Basic SQL query

SELECT *
FROM olist_customers_dataset 
WHERE customer_city = 'sao paulo'

--Comparison
SELECT *
FROM olist_order_items_dataset
WHERE price BETWEEN 100 AND 500

SELECT *
FROM olist_orders_dataset
WHERE order_status = 'delivered'
OR order_status = 'shipped'

--Mengetahui jumlah order berdasarkan order status

SELECT
    order_status,
    COUNT(*) AS jumlah_order
FROM olist_orders_dataset
GROUP BY order_status

--Aggregate function
SELECT
    COUNT(*) AS jumlah_item,
    SUM(price) AS total_sales,
    AVG(price) AS rata_rata_harga,
    MIN(price) AS harga_minimum,
    MAX(price) AS harga_maksimum
FROM olist_order_items_dataset

--Case when

SELECT
    product_id,
    price,
    CASE
        WHEN price < 100 THEN 'Murah'
        WHEN price <= 500 THEN 'Menengah'
        ELSE 'Mahal'
    END AS kategori_harga
FROM olist_order_items_dataset

--Kategorisasi data untuk melihat jumlah item berdasarkan kategori harga
SELECT
    CASE
        WHEN price < 100 THEN 'Murah'
        WHEN price <= 500 THEN 'Menengah'
        ELSE 'Mahal'
    END AS kategori_harga,
    COUNT(*) AS jumlah_item
FROM olist_order_items_dataset
GROUP BY kategori_harga
ORDER BY jumlah_item desc

--Join
SELECT
    c.customer_unique_id,
    c.customer_state,
    o.order_id,
    o.order_status
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
    
--Advanced SQL

    
--Ranking penjualan berdasarkan seller id
SELECT
    seller_id,
    SUM(price) AS total_sales,
    RANK() OVER (
        ORDER BY SUM(price) DESC
    ) AS ranking
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY ranking

--Ranking penjualan berdasarkan state dan seller id
SELECT
    s.seller_state,
    oi.seller_id,
    SUM(oi.price) AS total_sales,
    RANK() OVER (
        PARTITION BY s.seller_state
        ORDER BY SUM(oi.price) DESC
    ) AS ranking
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_state, oi.seller_id
ORDER BY s.seller_state, ranking


--Top 10 penjualan berdasarkan seller id
SELECT
    seller_id,
    SUM(price) AS total_sales
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY total_sales DESC
LIMIT 10


--Check outlier

--Table Customers
WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) 
        WITHIN GROUP (ORDER BY customer_zip_code_prefix) AS q1,
        
        PERCENTILE_CONT(0.75) 
        WITHIN GROUP (ORDER BY customer_zip_code_prefix) AS q3
    FROM customers
),

bounds AS (
    SELECT
        q1 - 1.5 * (q3 - q1) AS lower_bound,
        q3 + 1.5 * (q3 - q1) AS upper_bound
    FROM stats
)

SELECT
    COUNT(*) AS total_outlier
FROM customers c
CROSS JOIN bounds
WHERE c.customer_zip_code_prefix < lower_bound
   OR c.customer_zip_code_prefix > upper_bound

--Table Sellers
WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) 
        WITHIN GROUP (ORDER BY seller_zip_code_prefix) AS q1,
        
        PERCENTILE_CONT(0.75) 
        WITHIN GROUP (ORDER BY seller_zip_code_prefix) AS q3
    FROM olist_sellers_dataset
),

bounds AS (
    SELECT
        q1 - 1.5 * (q3 - q1) AS lower_bound,
        q3 + 1.5 * (q3 - q1) AS upper_bound
    FROM stats
)

SELECT
    COUNT(*) AS total_outlier
FROM olist_sellers_dataset s
CROSS JOIN bounds
WHERE s.seller_zip_code_prefix < lower_bound
   OR s.seller_zip_code_prefix > upper_bound


-- Hitung missing value nya

--Table Customers

SELECT 
    'customer_id' AS column_name, 
    COUNT(*) FILTER(WHERE customer_id IS NULL) AS missing_value
FROM olist_customers_dataset
UNION ALL
SELECT 
    'customer_unique_id', 
    COUNT(*) FILTER(WHERE customer_unique_id IS NULL)
FROM olist_customers_dataset
UNION ALL
SELECT 
    'customer_zip_code_prefix', 
    COUNT(*) FILTER(WHERE customer_zip_code_prefix IS NULL)
FROM olist_customers_dataset
UNION ALL
SELECT 
    'customer_city', 
    COUNT(*) FILTER(WHERE customer_city IS NULL)
FROM olist_customers_dataset
UNION ALL
SELECT 
    'customer_state', 
    COUNT(*) FILTER(WHERE customer_state IS NULL)
FROM olist_customers_dataset

--Table Sellers

SELECT 
    'seller_id' AS column_name, 
    COUNT(*) FILTER(WHERE seller_id IS NULL) AS missing_value
FROM olist_sellers_dataset
UNION ALL
SELECT 
    'seller_zip_code_prefix', 
    COUNT(*) FILTER(WHERE seller_zip_code_prefix IS NULL)
FROM olist_sellers_dataset
UNION ALL
SELECT 
    'seller_city', 
    COUNT(*) FILTER(WHERE seller_city IS NULL)
FROM olist_sellers_dataset
UNION ALL
SELECT 
    'seller_state', 
    COUNT(*) FILTER(WHERE seller_state IS NULL)
FROM olist_sellers_dataset

--Table Order Items

SELECT 
    'order_id' AS column_name, 
    COUNT(*) FILTER(WHERE order_id IS NULL) AS missing_value
FROM olist_order_items_dataset
UNION ALL
SELECT 
    'order_item_id', 
    COUNT(*) FILTER(WHERE order_item_id IS NULL)
FROM olist_order_items_dataset
UNION ALL
SELECT 
    'product_id', 
    COUNT(*) FILTER(WHERE product_id IS NULL)
FROM olist_order_items_dataset
UNION ALL
SELECT 
    'seller_id', 
    COUNT(*) FILTER(WHERE seller_id IS NULL)
FROM olist_order_items_dataset
UNION ALL
SELECT 
    'shipping_limit_date', 
    COUNT(*) FILTER(WHERE shipping_limit_date IS NULL)
FROM olist_order_items_dataset
UNION ALL
SELECT 
    'price', 
    COUNT(*) FILTER(WHERE price IS NULL)
FROM olist_order_items_dataset
UNION ALL
SELECT 
    'freight_value', 
    COUNT(*) FILTER(WHERE freight_value IS NULL)
FROM olist_order_items_dataset

--Table Orders

SELECT 
    'order_id' AS column_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_value
FROM olist_orders_dataset
UNION ALL
SELECT 
    'customer_id',
    COUNT(*) FILTER (WHERE customer_id IS NULL)
FROM olist_orders_dataset
UNION ALL
SELECT 
    'order_status',
    COUNT(*) FILTER (WHERE order_status IS NULL)
FROM olist_orders_dataset
UNION ALL
SELECT 
    'order_purchase_timestamp',
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL)
FROM olist_orders_dataset
UNION ALL
SELECT 
    'order_approved_at',
    COUNT(*) FILTER (WHERE order_approved_at IS NULL)
FROM olist_orders_dataset
UNION ALL
SELECT 
    'order_delivered_carrier_date',
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL)
FROM olist_orders_dataset
UNION ALL
SELECT 
    'order_delivered_customer_date',
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL)
FROM olist_orders_dataset
UNION ALL
SELECT 
    'order_estimated_delivery_date',
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL)
FROM olist_orders_dataset


--Hitung duplicate

--Table Customers
SELECT customer_id, COUNT(*)
FROM olist_customers_dataset
GROUP BY customer_id
HAVING COUNT(*) > 1

--Table Sellers
SELECT seller_id, COUNT(*)
FROM olist_sellers_dataset
GROUP BY seller_id
HAVING COUNT(*) > 1

--Table Order Items
SELECT order_id, order_item_id, COUNT(*)
FROM olist_order_items_dataset
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1

--Table Orders
SELECT order_id, COUNT(*)
FROM olist_orders_dataset
GROUP BY order_id
HAVING COUNT(*) > 1


--SQL Analysis & Insight

--Kontribusi penjualan setiap state, order terbanyak

create or replace view Revenue_per_state as
SELECT
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS jumlah_order,
    SUM(oi.price) AS total_sales
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
ORDER BY total_sales desc
LIMIT 3

--Jumlah untuk status order
create or replace view Total_order_status_per_category as
SELECT
    order_status,
    COUNT(*) AS jumlah_order
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY jumlah_order DESC

--Jumlah cancelled tiap state nya
create or replace view Total_order_status_per_state as
SELECT
    c.customer_state,
    COUNT(*) AS jumlah_order_cancelled
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'canceled'
GROUP BY c.customer_state
ORDER BY jumlah_order_cancelled DESC
LIMIT 3


