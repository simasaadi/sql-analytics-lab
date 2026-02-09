/* 03_performance_notes.sql
Goal: show “performance-aware” SQL patterns and what indexes would help.
Skills: EXPLAIN, selective filtering, join reduction, pre-aggregation, indexing suggestions.
*/

-- A) Baseline query: revenue by month and channel
explain (analyze, buffers)
with order_revenue as (
  select
    o.order_id,
    date_trunc('month', o.order_ts) as order_month,
    o.channel,
    sum(oi.quantity * oi.unit_price) as gross_revenue
  from fct_order o
  join fct_order_item oi on oi.order_id = o.order_id
  group by 1,2,3
)
select
  order_month,
  channel,
  count(*) as orders,
  round(sum(gross_revenue)::numeric, 2) as gross_revenue
from order_revenue
group by 1,2
order by 1,2;

-- B) More selective query: only completed orders (if your statuses include it)
-- If you don't have 'completed', change it to a status you DO have.
explain (analyze, buffers)
select
  date_trunc('month', o.order_ts) as order_month,
  count(distinct o.order_id) as orders,
  round(sum(oi.quantity * oi.unit_price)::numeric, 2) as gross_revenue
from fct_order o
join fct_order_item oi on oi.order_id = o.order_id
where o.order_status in ('completed','paid','shipped')
group by 1
order by 1;

-- C) Top customers by lifetime value (CTE + aggregation)
explain (analyze, buffers)
with customer_ltv as (
  select
    c.customer_id,
    c.full_name,
    round(sum(oi.quantity * oi.unit_price)::numeric, 2) as lifetime_value
  from dim_customer c
  join fct_order o on o.customer_id = c.customer_id
  join fct_order_item oi on oi.order_id = o.order_id
  group by 1,2
)
select *
from customer_ltv
order by lifetime_value desc
limit 10;

-- D) Index recommendations (DO NOT run in this file if you want it read-only)
-- These are the indexes that would typically help the queries above:
--   create index if not exists idx_fct_order_order_ts on fct_order(order_ts);
--   create index if not exists idx_fct_order_customer_id on fct_order(customer_id);
--   create index if not exists idx_fct_order_order_status on fct_order(order_status);
--   create index if not exists idx_fct_order_item_order_id on fct_order_item(order_id);
--   create index if not exists idx_fct_order_item_product_id on fct_order_item(product_id);
--
-- Keep them as comments here; if you want, we can create a separate file like 04_indexes.sql to apply them.



