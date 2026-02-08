\copy dim_customer(customer_id, full_name, email, created_at, country) FROM '/seed/customers.csv' CSV HEADER;
\copy dim_product(product_id, product_name, category, unit_price, is_active) FROM '/seed/products.csv' CSV HEADER;
\copy fct_order(order_id, customer_id, order_ts, order_status, channel) FROM '/seed/orders.csv' CSV HEADER;
\copy fct_order_item(order_id, product_id, quantity, unit_price) FROM '/seed/order_items.csv' CSV HEADER;
\copy fct_payment(payment_id, order_id, paid_ts, amount, payment_method, payment_status) FROM '/seed/payments.csv' CSV HEADER;
