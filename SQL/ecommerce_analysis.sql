/*
NOVA MARKET — E-COMMERCE REVENUE, CUSTOMER & PRODUCT ANALYTICS
PostgreSQL portfolio project

Author: Snehasis Sarkar
Focus: Data quality, revenue, customers, products, time series and business investigation

*/

-- ============================================================
-- PHASE 0 — DATABASE HEALTH CHECK
-- ============================================================

-- Q0.1 — Table sizes
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;


-- Q0.2 — Orders without order items
SELECT o.order_id
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;


-- Q0.3 — Order items referring to non-existent orders
SELECT oi.*
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Q0.4 — Order items referring to non-existent products
SELECT oi.*
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Q0.5 — Orders with multiple payment records
SELECT
    order_id,
    COUNT(*) AS payment_count
FROM payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_count DESC;


-- Q0.6 — Cancelled orders with payments
SELECT
    o.order_id,
    o.status,
    COUNT(p.order_id) AS payment_count,
    SUM(p.amount) AS payment_amount
FROM orders o
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.status = 'Cancelled'
GROUP BY o.order_id, o.status
ORDER BY o.order_id;


-- Q0.7 — Payment amount vs calculated order amount
WITH order_amounts AS (
    SELECT
        o.order_id,
        SUM(oi.quantity * oi.unit_price) AS calculated_order_amount
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id
),
payment_totals AS (
    SELECT
        order_id,
        SUM(amount) AS payment_amount
    FROM payments
    GROUP BY order_id
)
SELECT
    oa.order_id,
    ROUND(oa.calculated_order_amount, 2) AS calculated_order_amount,
    ROUND(pt.payment_amount, 2) AS payment_amount,
    ROUND(pt.payment_amount - oa.calculated_order_amount, 2) AS difference
FROM order_amounts oa
JOIN payment_totals pt
    ON oa.order_id = pt.order_id
ORDER BY ABS(pt.payment_amount - oa.calculated_order_amount) DESC;


-- ============================================================
-- PHASE 1 — BUSINESS OVERVIEW
-- ============================================================

-- Q1 — Customer base
SELECT COUNT(*) AS total_customers
FROM customers;


-- Q2 — Total orders
SELECT COUNT(*) AS total_orders
FROM orders;


-- Q3 — Order status distribution
SELECT
    status,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders),
        2
    ) AS percentage
FROM orders
GROUP BY status
ORDER BY order_count DESC;


-- Q4 — Total revenue from completed orders (Completed)

-- Q5 — Average order value (Completed)

-- Q6 — Top 10 products by revenue (Completed)

-- Q7 — Category performance (Completed)

-- Q8 — Highest-revenue category
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY revenue DESC
LIMIT 1;


-- Q9 — Products below average product revenue
WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS tot_rev
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT
    product_id,
    product_name,
    category,
    tot_rev
FROM product_revenue
WHERE tot_rev < (
    SELECT AVG(tot_rev)
    FROM product_revenue
)
ORDER BY tot_rev;


-- ============================================================
-- PHASE 2 — CUSTOMER ANALYTICS
-- ============================================================

-- Q10 — Top 10 customers by completed spending
SELECT
    c.customer_name,
    c.city,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(oi.quantity * oi.unit_price) AS total_spending
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_name, c.city
ORDER BY total_spending DESC
LIMIT 10;


-- Q11 — Average customer spending
WITH customer_expenditure AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price) AS total_expenditure
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    AVG(total_expenditure) AS average_customer_spending
FROM customer_expenditure;


-- Q12 — Customers spending above average
WITH customer_expenditure AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price) AS total_expenditure
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    total_expenditure
FROM customer_expenditure
WHERE total_expenditure > (
    SELECT AVG(total_expenditure)
    FROM customer_expenditure
)
ORDER BY total_expenditure DESC;


-- Q13 — Customer ranking within each city
WITH customer_spending AS (
    SELECT
        c.city,
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price) AS total_spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.city, c.customer_id, c.customer_name
)
SELECT
    city,
    customer_id,
    customer_name,
    total_spending,
    RANK() OVER (
        PARTITION BY city
        ORDER BY total_spending DESC
    ) AS spending_rank
FROM customer_spending
ORDER BY city, spending_rank;


-- Q14 — Customer value segmentation
WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price) AS total_spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    total_spending,
    CASE
        WHEN total_spending >= 100000 THEN 'High Value'
        WHEN total_spending >= 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_spending
ORDER BY total_spending DESC;


-- ============================================================
-- PHASE 3 — TIME SERIES
-- ============================================================

-- Q15 — Monthly revenue
SELECT
    EXTRACT(YEAR FROM o.order_date) AS order_year,
    EXTRACT(MONTH FROM o.order_date) AS order_month,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY
    EXTRACT(YEAR FROM o.order_date),
    EXTRACT(MONTH FROM o.order_date)
ORDER BY order_year, order_month;


-- Q16 — Monthly completed orders
SELECT
    EXTRACT(YEAR FROM order_date) AS order_year,
    EXTRACT(MONTH FROM order_date) AS order_month,
    COUNT(*) AS completed_orders
FROM orders
WHERE status = 'Completed'
GROUP BY
    EXTRACT(YEAR FROM order_date),
    EXTRACT(MONTH FROM order_date)
ORDER BY order_year, order_month;


-- Q17 — Month-over-month revenue growth
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::date AS month,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
),
with_previous AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    month,
    revenue,
    previous_month_revenue,
    ROUND(
        100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS growth_percentage
FROM with_previous
ORDER BY month;


-- Q18 — Highest-revenue month
SELECT
    EXTRACT(MONTH FROM o.order_date) AS month,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY month
ORDER BY revenue DESC
LIMIT 1;


-- Q19 — Lowest-revenue month
SELECT
    EXTRACT(MONTH FROM order_date) AS month,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY month
ORDER BY revenue ASC
LIMIT 1;


-- Q20 — Repeat customers
SELECT
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS completed_order_count,
    SUM(oi.quantity * oi.unit_price) AS total_spending
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY total_spending DESC;


-- Q21 — One-time customers
SELECT
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS completed_order_count
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) = 1
ORDER BY c.customer_name;


-- Q22 — Inactive customers
-- Definition: no completed purchase during the final 90 days of the dataset.
WITH dataset_end AS (
    SELECT MAX(order_date) AS max_order_date
    FROM orders
),
customer_last_purchase AS (
    SELECT
        c.customer_id,
        c.customer_name,
        MAX(o.order_date) AS last_purchase_date
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
       AND o.status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    last_purchase_date
FROM customer_last_purchase, dataset_end
WHERE last_purchase_date IS NULL
   OR last_purchase_date < dataset_end.max_order_date - INTERVAL '90 days'
ORDER BY last_purchase_date;


-- Q23 — Customers purchasing from at least 3 categories
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT p.category) AS category_count
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT p.category) >= 3
ORDER BY category_count DESC, c.customer_name;


-- ============================================================
-- PHASE 4 — BUSINESS INVESTIGATION
-- ============================================================

-- Q24 — First half vs second half revenue
SELECT
    EXTRACT(YEAR FROM o.order_date) AS order_year,
    CASE
        WHEN EXTRACT(MONTH FROM o.order_date) <= 6
            THEN 'First Half'
        ELSE 'Second Half'
    END AS half,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY
    EXTRACT(YEAR FROM o.order_date),
    CASE
        WHEN EXTRACT(MONTH FROM o.order_date) <= 6
            THEN 'First Half'
        ELSE 'Second Half'
    END
ORDER BY order_year, half;


-- Q25 — Order volume vs average order value
WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::date AS month,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    month,
    completed_orders,
    revenue,
    ROUND(revenue / NULLIF(completed_orders, 0), 2) AS average_order_value
FROM monthly_metrics
ORDER BY month;


-- Q26 — Category deterioration between first and second half
WITH category_revenue AS (
    SELECT
        EXTRACT(YEAR FROM o.order_date) AS order_year,
        p.category,
        CASE
            WHEN EXTRACT(MONTH FROM o.order_date) <= 6
                THEN 'First Half'
            ELSE 'Second Half'
        END AS half,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'Completed'
    GROUP BY
        EXTRACT(YEAR FROM o.order_date),
        p.category,
        CASE
            WHEN EXTRACT(MONTH FROM o.order_date) <= 6
                THEN 'First Half'
            ELSE 'Second Half'
        END
)
SELECT
    order_year,
    category,
    SUM(CASE WHEN half = 'First Half' THEN total_revenue ELSE 0 END) AS first_half_revenue,
    SUM(CASE WHEN half = 'Second Half' THEN total_revenue ELSE 0 END) AS second_half_revenue
FROM category_revenue
GROUP BY order_year, category
ORDER BY order_year, category;


-- Q27 — Product deterioration between first and second half
WITH product_revenue AS (
    SELECT
        EXTRACT(YEAR FROM o.order_date) AS order_year,
        p.product_name,
        p.product_id,
        CASE
            WHEN EXTRACT(MONTH FROM o.order_date) <= 6
                THEN 'First Half'
            ELSE 'Second Half'
        END AS half,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'Completed'
    GROUP BY
        EXTRACT(YEAR FROM o.order_date),
        p.product_name,
        p.product_id,
        CASE
            WHEN EXTRACT(MONTH FROM o.order_date) <= 6
                THEN 'First Half'
            ELSE 'Second Half'
        END
)
SELECT
    order_year,
    product_id,
    product_name,
    SUM(CASE WHEN half = 'First Half' THEN total_revenue ELSE 0 END) AS first_half_revenue,
    SUM(CASE WHEN half = 'Second Half' THEN total_revenue ELSE 0 END) AS second_half_revenue
FROM product_revenue
GROUP BY order_year, product_id, product_name
ORDER BY order_year, product_id, product_name;


-- Q28 — Active customer comparison by half-year
WITH customer_behaviour AS (
    SELECT
        EXTRACT(YEAR FROM o.order_date) AS order_year,
        CASE
            WHEN EXTRACT(MONTH FROM o.order_date) <= 6
                THEN 'First Half'
            ELSE 'Second Half'
        END AS half,
        COUNT(DISTINCT o.customer_id) AS active_customers
    FROM orders o
    WHERE o.status = 'Completed'
    GROUP BY
        EXTRACT(YEAR FROM o.order_date),
        CASE
            WHEN EXTRACT(MONTH FROM o.order_date) <= 6
                THEN 'First Half'
            ELSE 'Second Half'
        END
)
SELECT
    order_year,
    SUM(CASE WHEN half = 'First Half' THEN active_customers ELSE 0 END) AS first_half_customers,
    SUM(CASE WHEN half = 'Second Half' THEN active_customers ELSE 0 END) AS second_half_customers
FROM customer_behaviour
GROUP BY order_year
ORDER BY order_year;


-- Q29 — Return rate
-- ORIGINAL PRACTICE QUERY: not recovered from prior history.
-- Reconstruct after confirming the dataset's return/status semantics.


-- Q30 — Payment method analysis
WITH payment_methods AS (
    SELECT
        payment_method,
        COUNT(payment_method) AS number_of_payments,
        SUM(amount) AS total_payment_amount
    FROM payments
    GROUP BY payment_method
)
SELECT
    payment_method,
    number_of_payments,
    total_payment_amount,
    ROUND(
        100.0 * total_payment_amount
        / SUM(total_payment_amount) OVER (),
        2
    ) AS percentage_of_payment_amount
FROM payment_methods
ORDER BY total_payment_amount DESC;


-- ============================================================
-- PHASE 5 — ADVANCED SQL
-- ============================================================

-- Q31 — Second-highest-spending customer in each city
WITH customer_spending AS (
    SELECT
        c.city,
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.city, c.customer_id, c.customer_name
)
SELECT
    city,
    customer_id,
    customer_name,
    revenue
FROM (
    SELECT
        city,
        customer_id,
        customer_name,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY revenue DESC
        ) AS customer_rank
    FROM customer_spending
) ranked_customers
WHERE customer_rank = 2
ORDER BY city;


-- Q32 — Top 3 products in each category
WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.category, p.product_id, p.product_name
)
SELECT
    category,
    product_id,
    product_name,
    revenue
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS product_rank
    FROM product_revenue
) ranked_products
WHERE product_rank <= 3
ORDER BY category, product_rank;


-- Q33 — Customer percentage contribution to company revenue
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    revenue,
    ROUND(
        100.0 * revenue / SUM(revenue) OVER (),
        2
    ) AS revenue_contribution_percentage
FROM customer_revenue
ORDER BY revenue DESC;


-- Q34 — Customers above their city's average spending
WITH customer_spending AS (
    SELECT
        c.city,
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price) AS spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.city, c.customer_id, c.customer_name
),
city_averages AS (
    SELECT
        city,
        AVG(spending) AS city_average_spending
    FROM customer_spending
    GROUP BY city
)
SELECT
    cs.city,
    cs.customer_id,
    cs.customer_name,
    cs.spending,
    ca.city_average_spending
FROM customer_spending cs
JOIN city_averages ca
    ON cs.city = ca.city
WHERE cs.spending > ca.city_average_spending
ORDER BY cs.city, cs.spending DESC;


-- Q35 — Most popular product category for each city
WITH category_revenue AS (
    SELECT
        c.city,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.city, p.category
)
SELECT
    city,
    category,
    revenue
FROM (
    SELECT
        city,
        category,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY revenue DESC
        ) AS category_rank
    FROM category_revenue
) ranked_category
WHERE category_rank = 1
ORDER BY city;


-- Q36 — Three-month moving average of revenue
WITH monthly_revenue AS (
    SELECT
        EXTRACT(YEAR FROM o.order_date) AS order_year,
        EXTRACT(MONTH FROM o.order_date) AS order_month,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY
        EXTRACT(YEAR FROM o.order_date),
        EXTRACT(MONTH FROM o.order_date)
)
SELECT
    order_year,
    order_month,
    revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY order_year, order_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS three_month_moving_average
FROM monthly_revenue
ORDER BY order_year, order_month;


-- Q37 — First and most recent purchase date
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    MIN(o.order_date) AS first_purchase,
    MAX(o.order_date) AS latest_purchase
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY c.customer_id;


-- Q38 — Customer lifetime value using payment data
-- Assumption: payment records represent actual successful payment amounts.
SELECT
    c.customer_id,
    c.customer_name,
    SUM(p.amount) AS customer_lifetime_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY customer_lifetime_value DESC;


-- Q39 — High sales volume but unusually low revenue
WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT
    product_id,
    product_name,
    category,
    total_quantity,
    total_revenue
FROM product_sales
WHERE total_quantity > (
    SELECT AVG(total_quantity)
    FROM product_sales
)
AND total_revenue < (
    SELECT AVG(total_revenue)
    FROM product_sales
)
ORDER BY total_revenue ASC;


-- Q40 — Customer-level KPI analytical view
CREATE OR REPLACE VIEW customer_kpiiis AS
WITH KPI AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.email,
        c.city,
        o.order_id,
        o.order_date,
        SUM(oi.quantity) AS total_quantities,
        SUM(oi.quantity * oi.unit_price) AS total_purchase
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY
        c.customer_id,
        c.customer_name,
        c.email,
        c.city,
        o.order_id,
        o.order_date
)
SELECT
    customer_id,
    customer_name,
    email,
    city,
    SUM(total_quantities) AS total_quantities,
    SUM(total_purchase) AS total_purchase,
    AVG(total_purchase) AS average_order_value,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM KPI
GROUP BY
    customer_id,
    customer_name,
    email,
    city;


