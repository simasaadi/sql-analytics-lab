# Contributing

## Running locally
1. `docker compose up -d`
2. Run the queries:
   - `docker exec -i sql_analytics_lab_db psql -U postgres -d analytics < queries/01_dimensional_metrics.sql`
   - `docker exec -i sql_analytics_lab_db psql -U postgres -d analytics < queries/02_data_quality_checks.sql`
   - `docker exec -i sql_analytics_lab_db psql -U postgres -d analytics < queries/03_performance_notes.sql`

## Expectations
- Keep SQL readable (CTEs, clear naming, comments for intent).
- If you change query outputs, update the matching file in `expected_results/`.
- CI must stay green.
