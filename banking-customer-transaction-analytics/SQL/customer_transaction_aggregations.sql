-- Advanced Analytical View for Banking Customer & Transaction Metrics
CREATE OR REPLACE VIEW `banking-customer-transaction.banking_warehouse.vw_customer_transaction_summary` AS
WITH CustomerMetrics AS (
    SELECT 
        c.customer_id,
        c.signup_date,
        c.customer_segment,
        COUNT(t.transaction_id) AS total_transactions,
        SUM(t.transaction_amount) AS total_spend,
        AVG(t.transaction_amount) AS avg_transaction_size,
        MAX(t.transaction_date) AS last_transaction_date,
        -- Window function to rank customers by total spend percentile
        PERCENT_RANK() OVER (ORDER BY SUM(t.transaction_amount) DESC) AS spend_percentile
    FROM `banking-customer-transaction.banking_warehouse.customers` c
    LEFT JOIN `banking-customer-transaction.banking_warehouse.transactions` t 
        ON c.customer_id = t.customer_id
    GROUP BY c.customer_id, c.signup_date, c.customer_segment
)
SELECT 
    customer_id,
    signup_date,
    customer_segment,
    total_transactions,
    ROUND(total_spend, 2) AS total_spend,
    ROUND(avg_transaction_size, 2) AS avg_transaction_size,
    last_transaction_date,
    CASE 
        WHEN spend_percentile <= 0.10 THEN 'VIP / High Value'
        WHEN spend_percentile <= 0.40 THEN 'Mid Tier'
        ELSE 'Standard'
    END AS computed_tier
FROM CustomerMetrics;