/* 01_dimensional_metrics.sql
Goal: Quick business-facing metrics for a basic commerce dataset.
Skills: CTEs, joins, conditional aggregation, time grouping, NULL handling.
*/

with order_enriched as (
  select
    o.order_id,
    o.customer_id,
    o.order_ts,
    date_trunc('month', o.order_ts) as order_month,
    o.order_status,
    o.channel,
    coalesce(sum(oi.quantity * oi.unit_price), 0)::numeric(12,2) as order_gross_revenue
  from fct_order o
  left join fct_order_item oi
    on oi.order_id = o.order_id
  group by 1,2,3,4,5,6
),

month_summary as (
  select
    order_month,
    count(*) as orders,
    count(distinct customer_id) as active_customers,
    sum(order_gross_revenue)::numeric(12,2) as gross_revenue,
    (sum(order_gross_revenue) / nullif(count(*), 0))::numeric(12,2) as aov
  from order_enriched
  group by 1
)

select
  order_month,
  orders,
  active_customers,
  gross_revenue,
  aov
from month_summary
order by order_month;


# 01_dimensional_metrics.sql

```text
     order_month     | orders | active_customers | gross_revenue |  aov
---------------------+--------+------------------+---------------+-------
 2025-03-01 00:00:00 |     14 |               12 |        306.91 | 21.92
(1 row)

