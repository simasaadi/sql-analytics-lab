#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting containers"
docker compose up -d

echo "==> Running queries"
docker exec -i sql_analytics_lab_db psql -U postgres -d analytics < queries/01_dimensional_metrics.sql
docker exec -i sql_analytics_lab_db psql -U postgres -d analytics < queries/02_data_quality_checks.sql
docker exec -i sql_analytics_lab_db psql -U postgres -d analytics < queries/03_performance_notes.sql

echo "==> Done"
