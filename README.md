# sql-analytics-lab

A tiny SQL analytics lab (Postgres + Docker) with:
- business metrics query
- data quality checks
- performance notes (EXPLAIN plans)
- expected outputs saved in `expected_results/`

## How to run

```bat
docker compose up -d
docker ps
docker exec -it sql_analytics_lab_db psql -U postgres -d analytics -c "\dt"

docker exec -i sql_analytics_lab_db psql -U postgres -d analytics < queries\01_dimensional_metrics.sql
docker exec -i sql_analytics_lab_db psql -U postgres -d analytics < queries\02_data_quality_checks.sql
docker exec -i sql_analytics_lab_db psql -U postgres -d analytics < queries\03_performance_notes.sql
Expected results

See saved outputs in:

expected_results/01_dimensional_metrics.md

expected_results/02_data_quality_checks.md

expected_results/03_performance_notes.md

Project structure

schema.sql -> creates tables

load_seed.sql + seed/*.csv -> loads seed data

queries/*.sql -> analytics + data quality + performance

expected_results/*.md -> captured outputs for validation
