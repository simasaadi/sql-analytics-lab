DROP TABLE IF EXISTS fct_payment;
DROP TABLE IF EXISTS fct_order_item;
DROP TABLE IF EXISTS fct_order;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_customer;

CREATE TABLE dim_customer (
  customer_id   INT PRIMARY KEY,
  full_name     TEXT NOT NULL,
  email         TEXT,
  created_at    TIMESTAMP NOT NULL,
  country       TEXT
);

CREATE TABLE dim_product (
  product_id    INT PRIMARY KEY,
  product_name  TEXT NOT NULL,
  category      TEXT NOT NULL,
  unit_price    NUMERIC(12,2) NOT NULL,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE fct_order (
  order_id      INT PRIMARY KEY,
  customer_id   INT NOT NULL REFERENCES dim_customer(customer_id),
  order_ts      TIMESTAMP NOT NULL,
  order_status  TEXT NOT NULL,
  channel       TEXT NOT NULL
);

CREATE TABLE fct_order_item (
  order_id      INT NOT NULL REFERENCES fct_order(order_id),
  product_id    INT NOT NULL REFERENCES dim_product(product_id),
  quantity      INT NOT NULL CHECK (quantity > 0),
  unit_price    NUMERIC(12,2) NOT NULL,
  PRIMARY KEY (order_id, product_id)
);

CREATE TABLE fct_payment (
  payment_id     INT PRIMARY KEY,
  order_id       INT NOT NULL REFERENCES fct_order(order_id),
  paid_ts        TIMESTAMP,
  amount         NUMERIC(12,2) NOT NULL,
  payment_method TEXT NOT NULL,
  payment_status TEXT NOT NULL
);

-- Data quality results table (operational-style logging)
CREATE TABLE IF NOT EXISTS dq_results (
  dq_check_name TEXT PRIMARY KEY,
  status        TEXT NOT NULL CHECK (status IN ('PASS', 'FAIL')),
  failed_rows   INTEGER NOT NULL,
  run_ts        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

