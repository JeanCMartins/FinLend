{{
    config(
        materialized='table',
        partition_by={
            "field": "transaction_date",
            "data_type": "date",
            "granularity": "day"
        }
    )
}}

-- 1. Isolamos a tabela de settlements e resolvemos o UNNEST antes do JOIN
WITH prep_settlements AS (
    SELECT
        transaction_id,
        settlement_id,
        CAST(net_amount_cents AS FLOAT64) / 100 AS net_amount,
        CAST(fee_amount_cents AS FLOAT64) / 100 AS fee_amount,
        settlement_date,
        paid_at
    FROM {{ source('raw', 'settlements') }},
    UNNEST(transaction_ids) AS transaction_id
    -- Deduplicamos aqui, garantindo a relação 1:1 ANTES de cruzar com a base principal
    QUALIFY ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY settlement_date DESC) = 1
),

-- 2. Base de transações limpa
base_transactions AS (
    SELECT
        transaction_id,
        merchant_id,
        amount_brl,
        status,
        payment_method,
        DATE(created_at) AS transaction_date,
        created_at
    FROM {{ ref('stg_transactions') }}
    WHERE status IN ('captured', 'refunded', 'chargeback')
),

-- 3. Base de merchants
base_merchants AS (
    SELECT
        id AS merchant_id,
        trade_name AS merchant_name,
        mcc_code
    FROM {{ source('raw', 'merchants') }}
)

-- 4. JOIN final muito mais leve e performático
SELECT
    t.transaction_id,
    t.merchant_id,
    m.merchant_name,
    m.mcc_code,
    t.amount_brl,
    t.status,
    t.payment_method,
    t.transaction_date,
    t.created_at,
    s.settlement_id,
    s.net_amount,
    s.fee_amount,
    s.settlement_date,
    s.paid_at,
    
    -- Lógica de receita correta
    CASE
        WHEN t.status = 'captured' THEN t.amount_brl
        WHEN t.status IN ('refunded', 'chargeback') THEN t.amount_brl * -1
        ELSE 0
    END AS revenue_impact

FROM base_transactions AS t
LEFT JOIN base_merchants AS m
    ON t.merchant_id = m.merchant_id
LEFT JOIN prep_settlements AS s
    ON t.transaction_id = s.transaction_id