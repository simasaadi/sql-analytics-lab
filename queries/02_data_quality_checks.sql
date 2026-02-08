/* 02_data_quality_checks.sql
Goal: basic data quality checks for the ecommerce dataset.
Skills: NULL checks, duplicates, referential integrity, range checks, reconciliation.
*/

-- 0) Quick row counts (sanity)
select 'dim_customer' as table_name, count(*) as rows from dim_customer
union all select 'dim_product', count(*) from dim_product
union all select 'fct_order', count(*) from fct_order
union all select 'fct_order_item', count(*) from fct_order_item
union all select 'fct_payment', count(*) from fct_payment
order by 1;

-- 1) Primary-key duplicate checks (should return 0 rows in "duplicate_groups")
select 'dim_customer' as check_name,
       count(*) as duplicate_groups
from (
  select customer_id
  from dim_customer
  group by customer_id
  having count(*) > 1
) d
union all
select 'dim_product',
       count(*)
from (
  select product_id
  from dim_product
  group by product_id
  having count(*) > 1
) d
union all
select 'fct_order',
       count(*)
from (
  select order_id
  from fct_order
  group by order_id
  having count(*) > 1
) d
union all
select 'fct_payment',
       count(*)
from (
  select payment_id
  from fct_payment
  group by payment_id
  having count(*) > 1
) d
order by 1;

-- 2) Null/blank checks on key fields (counts should be 0 ideally)
select
  sum(case when customer_id is null then 1 else 0 end) as null_customer_id,
  sum(case when full_name is null or btrim(full_name) = '' then 1 else 0 end) as blank_full_name,
  sum(case when email is null or btrim(email) = '' then 1 else 0 end) as blank_email,
  sum(case when created_at is null then 1 else 0 end) as null_created_at,
  sum(case when country is null or btrim(country) = '' then 1 else 0 end) as blank_country
from dim_customer;

select
  sum(case when product_id is null then 1 else 0 end) as null_product_id,
  sum(case when product_name is null or btrim(product_name) = '' then 1 else 0 end) as blank_product_name,
  sum(case when category is null or btrim(category) = '' then 1 else 0 end) as blank_category,
  sum(case when unit_price is null then 1 else 0 end) as null_unit_price
from dim_product;

select
  sum(case when order_id is null then 1 else 0 end) as null_order_id,
  sum(case when customer_id is null then 1 else 0 end) as null_customer_id,
  sum(case when order_ts is null then 1 else 0 end) as null_order_ts,
  sum(case when order_status is null or btrim(order_status) = '' then 1 else 0 end) as blank_order_status,
  sum(case when channel is null or btrim(channel) = '' then 1 else 0 end) as blank_channel
from fct_order;

-- 3) Referential integrity checks (should return 0 counts)
select
  'orders_missing_customer' as check_name,
  count(*) as rows
from fct_order o
left join dim_customer c on c.customer_id = o.customer_id
where c.customer_id is null;

select
  'order_items_missing_order' as check_name,
  count(*) as rows
from fct_order_item oi
left join fct_order o on o.order_id = oi.order_id
where o.order_id is null;

select
  'order_items_missing_product' as check_name,
  count(*) as rows
from fct_order_item oi
left join dim_product p on p.product_id = oi.product_id
where p.product_id is null;

select
  'payments_missing_order' as check_name,
  count(*) as rows
from fct_payment p
left join fct_order o on o.order_id = p.order_id
where o.order_id is null;

-- 4) Value/range checks (should return 0 counts)
select
  'negative_or_zero_quantity' as check_name,
  count(*) as rows
from fct_order_item
where quantity is null or quantity <= 0;

select
  'negative_unit_price_in_items' as check_name,
  count(*) as rows
from fct_order_item
where unit_price is null or unit_price < 0;

select
  'negative_unit_price_in_products' as check_name,
  count(*) as rows
from dim_product
where unit_price is null or unit_price < 0;

select
  'invalid_payment_amount' as check_name,
  count(*) as rows
from fct_payment
where amount is null or amount < 0;

-- 5) Reconciliation: order gross from items vs payments (by order)
with order_items_gross as (
  select
    order_id,
    round(sum(quantity * unit_price)::numeric, 2) as items_gross
  from fct_order_item
  group by order_id
),
order_payments as (
  select
    order_id,
    round(sum(amount)::numeric, 2) as paid_amount
  from fct_payment
  group by order_id
)
select
  o.order_id,
  coalesce(ig.items_gross, 0) as items_gross,
  coalesce(op.paid_amount, 0) as paid_amount,
  (coalesce(op.paid_amount, 0) - coalesce(ig.items_gross, 0))::numeric(12,2) as paid_minus_items
from fct_order o
left join order_items_gross ig on ig.order_id = o.order_id
left join order_payments op on op.order_id = o.order_id
order by abs(coalesce(op.paid_amount, 0) - coalesce(ig.items_gross, 0)) desc, o.order_id
limit 20;


# 02 — Data quality checks (expected output)

# 02 — Data quality checks (expected output)

```text
   table_name   | rows
----------------+------
 dim_customer   |   12
 dim_product    |   12
 fct_order      |   14
 fct_order_item |   29
 fct_payment    |   14
(5 rows)

  check_name  | duplicate_groups
--------------+------------------
 dim_customer |                0
 dim_product  |                0
 fct_order    |                0
 fct_payment  |                0
(4 rows)

 null_customer_id | blank_full_name | blank_email | null_created_at | blank_country
------------------+-----------------+-------------+-----------------+---------------
                0 |               0 |           1 |               0 |             0
(1 row)

 null_product_id | blank_product_name | blank_category | null_unit_price
-----------------+--------------------+----------------+-----------------
               0 |                  0 |              0 |               0
(1 row)

 null_order_id | null_customer_id | null_order_ts | blank_order_status | blank_channel
---------------+------------------+---------------+--------------------+---------------
             0 |                0 |             0 |                  0 |             0
(1 row)

       check_name        | rows
-------------------------+------
 orders_missing_customer |    0
(1 row)

        check_name         | rows
---------------------------+------
 order_items_missing_order |    0
(1 row)

         check_name          | rows
-----------------------------+------
 order_items_missing_product |    0
(1 row)

       check_name       | rows
------------------------+------
 payments_missing_order |    0
(1 row)

        check_name         | rows
---------------------------+------
 negative_or_zero_quantity |    0
(1 row)

          check_name          | rows
------------------------------+------
 negative_unit_price_in_items |    0
(1 row)

           check_name            | rows
---------------------------------+------
 negative_unit_price_in_products |    0
(1 row)

       check_name       | rows
------------------------+------
 invalid_payment_amount |    0
(1 row)

 order_id | items_gross | paid_amount | paid_minus_items
----------+-------------+-------------+------------------
     3012 |       23.40 |       23.49 |             0.09
     3001 |       15.45 |       15.45 |             0.00
     3002 |       14.55 |       14.55 |             0.00
     3003 |       19.99 |       19.99 |             0.00
     3004 |       12.75 |       12.75 |             0.00
     3005 |       21.49 |       21.49 |             0.00
     3006 |       42.97 |       42.97 |             0.00
     3007 |        8.80 |        8.80 |             0.00
     3008 |       57.98 |       57.98 |             0.00
     3009 |       17.40 |       17.40 |             0.00
     3010 |       23.00 |       23.00 |             0.00
     3011 |       12.35 |       12.35 |             0.00
     3013 |       28.98 |       28.98 |             0.00
     3014 |        7.80 |        7.80 |             0.00
(14 rows)
