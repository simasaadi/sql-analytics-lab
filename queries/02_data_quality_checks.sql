-- 02_data_quality_checks.sql
-- Writes PASS/FAIL results into dq_results, then prints the latest results.

-- NOTE:
-- Replace the three "FAILED_ROWS_QUERY" sections below with YOUR actual checks
-- (use the same tables/columns you already have in your current file).

BEGIN;

-- Optional: keep only the latest run per check name (UPSERT)
-- Each insert overwrites the previous row for that check_name.
-- This makes the table a “current status” dashboard.
WITH
check_01 AS (
  -- FAILED_ROWS_QUERY #1 (example: NULL primary key)
  SELECT COUNT(*)::int AS failed_rows
  FROM <YOUR_TABLE_1>
  WHERE <YOUR_NULL_OR_INVALID_CONDITION_1>
),
check_02 AS (
  -- FAILED_ROWS_QUERY #2 (example: orphan foreign keys)
  SELECT COUNT(*)::int AS failed_rows
  FROM <YOUR_TABLE_2> t
  LEFT JOIN <YOUR_TABLE_1> d ON t.<fk_col> = d.<pk_col>
  WHERE d.<pk_col> IS NULL
),
check_03 AS (
  -- FAILED_ROWS_QUERY #3 (example: negative amounts)
  SELECT COUNT(*)::int AS failed_rows
  FROM <YOUR_TABLE_3>
  WHERE <YOUR_NEGATIVE_OR_RANGE_CONDITION_3>
)

INSERT INTO dq_results (dq_check_name, status, failed_rows, run_ts)
SELECT
  'check_01__<short_name_here>',
  CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END,
  failed_rows,
  NOW()
FROM check_01
ON CONFLICT (dq_check_name)
DO UPDATE SET
  status = EXCLUDED.status,
  failed_rows = EXCLUDED.failed_rows,
  run_ts = EXCLUDED.run_ts;

INSERT INTO dq_results (dq_check_name, status, failed_rows, run_ts)
SELECT
  'check_02__<short_name_here>',
  CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END,
  failed_rows,
  NOW()
FROM check_02
ON CONFLICT (dq_check_name)
DO UPDATE SET
  status = EXCLUDED.status,
  failed_rows = EXCLUDED.failed_rows,
  run_ts = EXCLUDED.run_ts;

INSERT INTO dq_results (dq_check_name, status, failed_rows, run_ts)
SELECT
  'check_03__<short_name_here>',
  CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END,
  failed_rows,
  NOW()
FROM check_03
ON CONFLICT (dq_check_name)
DO UPDATE SET
  status = EXCLUDED.status,
  failed_rows = EXCLUDED.failed_rows,
  run_ts = EXCLUDED.run_ts;

COMMIT;

-- Print the latest results (what recruiters want to see)
SELECT dq_check_name, status, failed_rows, run_ts
FROM dq_results
ORDER BY run_ts DESC, dq_check_name;
