WITH source AS (
    SELECT *
    FROM {{ source('raw', 'transactions') }}
),

renamed AS (
    SELECT
        transaction_id,
        merchant_id,
        customer_id,
        amount_cents,
        
        -- Adicionado CAST explícito para evitar truncamento em divisão de inteiros
        CAST(amount_cents AS FLOAT64) / 100 AS amount_brl,
        
        status,
        payment_method,
        created_at,
        updated_at,
        metadata,
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM source
    -- O filtro "WHERE status != 'test'" foi removido propositalmente.
    -- A camada staging deve manter a granularidade 1:1 com a raw.
)

SELECT * FROM renamed
