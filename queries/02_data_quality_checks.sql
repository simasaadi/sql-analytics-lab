-- 02_data_quality_checks.sql
-- Writes standardized PASS/FAIL rows into dq_results, then prints the latest results.

BEGIN;

WITH checks AS (

  -- 1) Null / blank key checks
  SELECT 'fct_order__missing_order_id' AS dq_check_name,
         COUNT(*)::int AS failed_rows
  FROM fct_order
  WHERE order_id IS NULL

  UNION ALL
  SELECT 'dim_customer__missing_customer_id',
         COUNT(*)::int
  FROM dim_customer
  WHERE customer_id IS NULL

  UNION ALL
  SELECT 'dim_product__missing_product_id',
         COUNT(*)::int
  FROM dim_product
  WHERE product_id IS NULL

  -- 2) Blank required fields
  UNION ALL
  SELECT 'fct_order__blank_order_status',
         COUNT(*)::int
  FROM fct_order
  WHERE order_status IS NULL OR btrim(order_status) = ''

  UNION ALL
  SELECT 'fct_order__blank_channel',
         COUNT(*)::int
  FROM fct_order
  WHERE channel IS NULL OR btrim(channel) = ''

  -- 3) Referential integrity
  UNION ALL
  SELECT 'fct_order__missing_customer_dim',
         COUNT(*)::int
  FROM fct_order o
  LEFT JOIN dim_customer c ON c.customer_id = o.customer_id
  WHERE o.customer_id IS NOT NULL
    AND c.customer_id IS NULL

  UNION ALL
  SELECT 'fct_order_item__missing_order_fact',
         COUNT(*)::int
  FROM fct_order_item oi
  LEFT JOIN fct_order o ON o.order_id = oi.order_id
  WHERE oi.order_id IS NOT NULL
    AND o.order_id IS NULL

  UNION ALL
  SELECT 'fct_order_item__missing_product_dim',
         COUNT(*)::int
  FROM fct_order_item oi
  LEFT JOIN dim_product p ON p.product_id = oi.product_id
  WHERE oi.product_id IS NOT NULL
    AND p.product_id IS NULL

  UNION ALL
  SELECT 'fct_payment__missing_order_fact',
         COUNT(*)::int
  FROM fct_payment pay
  LEFT JOIN fct_order o ON o.order_id = pay.order_id
  WHERE pay.order_id IS NOT NULL
    AND o.order_id IS NULL

  -- 4) Value / range checks
  UNION ALL
  SELECT 'fct_order_item__non_positive_quantity',
         COUNT(*)::int
  FROM fct_order_item
  WHERE quantity IS NULL OR quantity <= 0

  UNION ALL
  SELECT 'fct_order_item__negative_unit_price',
         COUNT(*)::int
  FROM fct_order_item
  WHERE unit_price IS NULL OR unit_price < 0

  UNION ALL
  SELECT 'dim_product__negative_unit_price',
         COUNT(*)::int
  FROM dim_product
  WHERE unit_price IS NULL OR unit_price < 0

  UNION ALL
  SELECT 'fct_payment__negative_amount',
         COUNT(*)::int
  FROM fct_payment
  WHERE amount IS NULL OR amount < 0

  -- 5) Reconciliation: payments vs items gross (count mismatched orders)
  UNION ALL
  SELECT 'recon__payments_minus_items_not_zero',
         COUNT(*)::int
  FROM (
    WITH order_items_gross AS (
      SELECT
        order_id,
        ROUND(SUM(quantity * unit_price)::numeric, 2) AS items_gross
      FROM fct_order_item
      GROUP BY order_id
    ),
    order_payments AS (
      SELECT
        order_id,
        ROUND(SUM(amount)::numeric, 2) AS paid_amount
      FROM fct_payment
      GROUP BY order_id
    )
    SELECT
      o.order_id,
      COALESCE(op.paid_amount, 0) - COALESCE(ig.items_gross, 0) AS diff
    FROM fct_order o
    LEFT JOIN order_items_gross ig ON ig.order_id = o.order_id
    LEFT JOIN order_payments op ON op.order_id = o.order_id
  ) t
  WHERE ROUND(t.diff::numeric, 2) <> 0

)

INSERT INTO dq_results (dq_check_name, status, failed_rows, run_ts)
SELECT
  dq_check_name,
  CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
  failed_rows,
  NOW() AS run_ts
FROM checks
ON CONFLICT (dq_check_name)
DO UPDATE SET
  status = EXCLUDED.status,
  failed_rows = EXCLUDED.failed_rows,
  run_ts = EXCLUDED.run_ts;

COMMIT;

-- Print the latest results (this is what you’ll snapshot in expected_results)
SELECT dq_check_name, status, failed_rows, run_ts
FROM dq_results
ORDER BY run_ts DESC, dq_check_name;
