-- Performance indexes (demo)
CREATE INDEX IF NOT EXISTS idx_fct_order_item_order_id ON fct_order_item(order_id);
CREATE INDEX IF NOT EXISTS idx_fct_order_customer_id   ON fct_order(customer_id);
CREATE INDEX IF NOT EXISTS idx_fct_order_order_ts      ON fct_order(order_ts);
CREATE INDEX IF NOT EXISTS idx_fct_payment_order_id    ON fct_payment(order_id);
