# 03 — Performance notes (EXPLAIN)

## What this is proving
This repo includes a small but realistic performance workflow:
- create indexes (`queries/00_indexes.sql`)
- validate query plans using `EXPLAIN (ANALYZE, BUFFERS)`
- keep CI green to prevent regressions

## Before vs after (how to interpret)
Baseline “before indexes” numbers were captured locally before the index script was added.
CI applies indexes first and re-checks the indexed plan stays healthy on every push.

### Before (local baseline, pre-index)
- Access path: Seq Scan / Hash Join driven by seq scans
- Example signal: higher buffer reads, higher execution time

### After (indexed, validated in CI)
- Access path: Index Scan / Index Only Scan where appropriate
- Example signal: fewer buffers, lower execution time

## Evidence snippets (replace with your own)
**Before**
- Seq Scan on fct_order_item
- Execution Time: XXX ms

**After**
- Index Scan using idx_fct_order_item_order_id on fct_order_item
- Execution Time: YYY ms
