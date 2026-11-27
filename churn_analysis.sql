CREATE DATABASE retail_churn;

USE retail_churn;



ALTER USER 'root'@'localhost' IDENTIFIED BY 'Churn2026Pass';

USE retail_churn;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT CustomerID) AS customers,
       MIN(InvoiceDate) AS first_date,
       MAX(InvoiceDate) AS last_date
FROM sales;

USE retail_churn;

-- Should return 0 (no invalid sales rows)
SELECT COUNT(*) AS bad_rows FROM sales WHERE Quantity <= 0 OR Price <= 0;

-- Should show 18390
SELECT COUNT(*) AS return_rows FROM returns;

-- Overall size of the business
SELECT COUNT(DISTINCT Invoice) AS invoices,
       ROUND(SUM(Revenue), 2) AS total_revenue
FROM sales;

DROP TABLE IF EXISTS customer_summary;

CREATE TABLE customer_summary AS
SELECT
    CustomerID,
    MIN(InvoiceDate)                         AS first_purchase,
    MAX(InvoiceDate)                         AS last_purchase,
    COUNT(DISTINCT Invoice)                  AS total_orders,
    ROUND(SUM(Revenue), 2)                   AS total_revenue,
    ROUND(SUM(Revenue) / COUNT(DISTINCT Invoice), 2) AS avg_order_value,
    DATEDIFF('2011-12-10', MAX(InvoiceDate)) AS days_since_last_purchase
FROM sales
GROUP BY CustomerID;

SELECT COUNT(*) FROM customer_summary;   -- should be 5878
SELECT * FROM customer_summary ORDER BY total_revenue DESC LIMIT 10;

SELECT
    COUNT(*) AS customers,
    ROUND(100 * SUM(days_since_last_purchase > 90)  / COUNT(*), 1) AS pct_inactive_90_days,
    ROUND(100 * SUM(days_since_last_purchase > 180) / COUNT(*), 1) AS pct_inactive_180_days,
    ROUND(100 * SUM(days_since_last_purchase > 365) / COUNT(*), 1) AS pct_inactive_365_days
FROM customer_summary;

USE retail_churn;

SELECT * FROM returns WHERE CustomerID = 16446;

SELECT ROUND(SUM(Revenue), 2) AS total_returns_value FROM returns;

USE retail_churn;

DROP TABLE IF EXISTS customer_summary_net;

CREATE TABLE customer_summary_net AS
SELECT
    cs.*,
    COALESCE(r.returns_value, 0) AS returns_value,
    ROUND(cs.total_revenue + COALESCE(r.returns_value, 0), 2) AS net_revenue
FROM customer_summary cs
LEFT JOIN (
    SELECT CustomerID, ROUND(SUM(Revenue), 2) AS returns_value
    FROM returns
    GROUP BY CustomerID
) r ON cs.CustomerID = r.CustomerID;

SELECT * FROM customer_summary_net ORDER BY net_revenue DESC LIMIT 10;



USE retail_churn;

WITH orders AS (
    SELECT CustomerID, Invoice, MIN(InvoiceDate) AS order_date
    FROM sales
    GROUP BY CustomerID, Invoice
),
gaps AS (
    SELECT CustomerID,
           DATEDIFF(order_date,
                    LAG(order_date) OVER (PARTITION BY CustomerID ORDER BY order_date)) AS gap_days
    FROM orders
)
SELECT
    COUNT(gap_days) AS total_gaps,
    ROUND(100 * SUM(gap_days <= 30)  / COUNT(gap_days), 1) AS pct_within_30_days,
    ROUND(100 * SUM(gap_days <= 90)  / COUNT(gap_days), 1) AS pct_within_90_days,
    ROUND(100 * SUM(gap_days <= 180) / COUNT(gap_days), 1) AS pct_within_180_days
FROM gaps
WHERE gap_days IS NOT NULL;


USE retail_churn;

DROP TABLE IF EXISTS customer_churn;

CREATE TABLE customer_churn AS
SELECT *,
       CASE WHEN days_since_last_purchase > 180 THEN 1 ELSE 0 END AS churned
FROM customer_summary_net;

-- Churned vs active customers
SELECT churned,
       COUNT(*) AS customers,
       ROUND(AVG(total_orders), 1) AS avg_orders,
       ROUND(SUM(net_revenue), 0) AS total_net_revenue,
       ROUND(AVG(net_revenue), 0) AS avg_net_revenue
FROM customer_churn
GROUP BY churned;



USE retail_churn;

-- Does churn depend on how many orders a customer has made?
SELECT CASE WHEN total_orders = 1 THEN '1 order'
            WHEN total_orders BETWEEN 2 AND 4 THEN '2-4 orders'
            ELSE '5+ orders' END AS order_group,
       COUNT(*) AS customers,
       ROUND(100 * AVG(churned), 1) AS churn_rate_pct
FROM customer_churn
GROUP BY order_group
ORDER BY MIN(total_orders);


ALTER USER 'root'@'localhost' IDENTIFIED BY 'Churn2026Pass';
USE retail_churn;

DROP TABLE IF EXISTS cohort_retention;

CREATE TABLE cohort_retention AS
WITH first_month AS (
    SELECT CustomerID,
           CAST(DATE_FORMAT(MIN(InvoiceDate), '%Y-%m-01') AS DATE) AS cohort_month
    FROM sales
    GROUP BY CustomerID
),
activity AS (
    SELECT DISTINCT CustomerID,
           CAST(DATE_FORMAT(InvoiceDate, '%Y-%m-01') AS DATE) AS active_month
    FROM sales
),
cohort_counts AS (
    SELECT f.cohort_month,
           TIMESTAMPDIFF(MONTH, f.cohort_month, a.active_month) AS month_number,
           COUNT(DISTINCT a.CustomerID) AS active_customers
    FROM first_month f
    JOIN activity a ON f.CustomerID = a.CustomerID
    GROUP BY f.cohort_month, month_number
)
SELECT cohort_month, month_number, active_customers,
       ROUND(100 * active_customers /
             FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY month_number), 1) AS retention_pct
FROM cohort_counts;

SELECT * FROM cohort_retention
WHERE cohort_month = '2010-01-01'
ORDER BY month_number;