{{ config(materialized='table') }}

WITH aggregated_merchants AS (
    SELECT
        merchant_id,
        merchant_name,
        mcc_code,
        COUNT(merchant_id) AS total_transactions,
        SUM(revenue_impact) AS total_revenue,
        SUM(fee_amount) AS total_fees,
        
        -- Substituição do SUM(CASE...) por COUNTIF (mais performático no BigQuery)
        COUNTIF(status = 'chargeback') AS chargebacks,
        
        MIN(transaction_date) AS first_transaction,
        MAX(transaction_date) AS last_transaction
    FROM {{ ref('revenue_report') }}
    -- Boa prática: evitar "GROUP BY 1, 2, 3" e explicitar as colunas
    GROUP BY 
        merchant_id, 
        merchant_name, 
        mcc_code
)

SELECT
    merchant_id,
    merchant_name,
    mcc_code,
    total_transactions,
    total_revenue,
    total_fees,
    chargebacks,
    
    -- Substituição da divisão direta por SAFE_DIVIDE para evitar quebra do pipeline
    SAFE_DIVIDE(chargebacks, total_transactions) AS chargeback_rate,
    
    first_transaction,
    last_transaction
FROM aggregated_merchants