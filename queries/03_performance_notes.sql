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




# 03 — Performance notes (EXPLAIN ANALYZE expected output)

## Plan 1
```text
                                                               QUERY PLAN                                                  
-----------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=113.85..114.35 rows=200 width=80) (actual time=0.089..0.091 rows=2 loops=1)
   Sort Key: (date_trunc('month'::text, o.order_ts)), o.channel
   Sort Method: quicksort  Memory: 25kB
   Buffers: shared hit=8
   ->  HashAggregate  (cost=103.20..106.20 rows=200 width=80) (actual time=0.065..0.067 rows=2 loops=1)
         Group Key: (date_trunc('month'::text, o.order_ts)), o.channel
         Batches: 1  Memory Usage: 40kB
         Buffers: shared hit=2
         ->  HashAggregate  (cost=76.95..88.20 rows=750 width=76) (actual time=0.055..0.061 rows=14 loops=1)
               Group Key: o.order_id, date_trunc('month'::text, o.order_ts)
               Batches: 1  Memory Usage: 49kB
               Buffers: shared hit=2
               ->  Hash Join  (cost=26.88..58.83 rows=1450 width=64) (actual time=0.029..0.038 rows=29 loops=1)
                     Hash Cond: (oi.order_id = o.order_id)
                     Buffers: shared hit=2
                     ->  Seq Scan on fct_order_item oi  (cost=0.00..24.50 rows=1450 width=24) (actual time=0.005..0.007 rows=29 loops=1)
                           Buffers: shared hit=1
                     ->  Hash  (cost=17.50..17.50 rows=750 width=44) (actual time=0.009..0.010 rows=14 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 9kB
                           Buffers: shared hit=1
                           ->  Seq Scan on fct_order o  (cost=0.00..17.50 rows=750 width=44) (actual time=0.003..0.005 rows=14 loops=1)
                                 Buffers: shared hit=1
 Planning:
   Buffers: shared hit=140
 Planning Time: 0.366 ms
 Execution Time: 0.213 ms
(26 rows)


                                                            QUERY PLAN                                                     
-----------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=49.29..49.80 rows=11 width=48) (actual time=0.162..0.165 rows=1 loops=1)
   Group Key: (date_trunc('month'::text, o.order_ts))
   Buffers: shared hit=5
   ->  Sort  (cost=49.29..49.34 rows=21 width=32) (actual time=0.129..0.134 rows=26 loops=1)
         Sort Key: (date_trunc('month'::text, o.order_ts)), o.order_id
         Sort Method: quicksort  Memory: 26kB
         Buffers: shared hit=5
         ->  Hash Join  (cost=20.45..48.83 rows=21 width=32) (actual time=0.040..0.099 rows=26 loops=1)
               Hash Cond: (oi.order_id = o.order_id)
               Buffers: shared hit=2
               ->  Seq Scan on fct_order_item oi  (cost=0.00..24.50 rows=1450 width=24) (actual time=0.006..0.010 rows=29 loops=1)
                     Buffers: shared hit=1
               ->  Hash  (cost=20.31..20.31 rows=11 width=12) (actual time=0.021..0.022 rows=12 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 9kB
                     Buffers: shared hit=1
                     ->  Seq Scan on fct_order o  (cost=0.00..20.31 rows=11 width=12) (actual time=0.007..0.012 rows=12 loops=1)
                           Filter: (order_status = ANY ('{completed,paid,shipped}'::text[]))
                           Rows Removed by Filter: 2
                           Buffers: shared hit=1
 Planning:
   Buffers: shared hit=3
 Planning Time: 0.289 ms
 Execution Time: 0.215 ms
(23 rows)

                                                                  QUERY PLAN                                               
-----------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=119.00..119.02 rows=10 width=68) (actual time=0.069..0.072 rows=10 loops=1)
   Buffers: shared hit=6
   ->  Sort  (cost=119.00..120.50 rows=600 width=68) (actual time=0.068..0.070 rows=10 loops=1)
         Sort Key: (round(sum(((oi.quantity)::numeric * oi.unit_price)), 2)) DESC
         Sort Method: quicksort  Memory: 25kB
         Buffers: shared hit=6
         ->  HashAggregate  (cost=97.03..106.03 rows=600 width=68) (actual time=0.049..0.055 rows=12 loops=1)
               Group Key: c.customer_id
               Batches: 1  Memory Usage: 49kB
               Buffers: shared hit=3
               ->  Hash Join  (cost=50.38..82.53 rows=1450 width=56) (actual time=0.023..0.033 rows=29 loops=1)
                     Hash Cond: (o.customer_id = c.customer_id)
                     Buffers: shared hit=3
                     ->  Hash Join  (cost=26.88..55.20 rows=1450 width=24) (actual time=0.009..0.015 rows=29 loops=1)
                           Hash Cond: (oi.order_id = o.order_id)
                           Buffers: shared hit=2
                           ->  Seq Scan on fct_order_item oi  (cost=0.00..24.50 rows=1450 width=24) (actual time=0.001..0.003 rows=29 loops=1)
                                 Buffers: shared hit=1
                           ->  Hash  (cost=17.50..17.50 rows=750 width=8) (actual time=0.005..0.005 rows=14 loops=1)
                                 Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                 Buffers: shared hit=1
                                 ->  Seq Scan on fct_order o  (cost=0.00..17.50 rows=750 width=8) (actual time=0.001..0.002 rows=14 loops=1)
                                       Buffers: shared hit=1
                     ->  Hash  (cost=16.00..16.00 rows=600 width=36) (actual time=0.008..0.008 rows=12 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 9kB
                           Buffers: shared hit=1
                           ->  Seq Scan on dim_customer c  (cost=0.00..16.00 rows=600 width=36) (actual time=0.004..0.005 rows=12 loops=1)
                                 Buffers: shared hit=1
 Planning:
   Buffers: shared hit=40
 Planning Time: 0.259 ms
 Execution Time: 0.103 ms
(32 rows)

