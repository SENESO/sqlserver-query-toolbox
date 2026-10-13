# sqlserver-query-toolbox

A set of SQL Server scripts covering the queries backend developers actually use: window functions, CTEs, indexing, performance diagnostics, date handling, and transactions. Every script runs against the same small sample database.

**Requirements:** SQL Server 2017 or later (or Azure SQL Database). Script `03` uses `STRING_AGG`, which needs 2017+; everything else works on 2012+.

## Run order

Scripts build on each other — run them in order:

| File | What it covers |
|---|---|
| `00-setup-sample-data.sql` | Creates the sample schema (`Departments`, `Employees`, `Sales`) and loads data. Run once, first. |
| `01-window-functions.sql` | `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `NTILE`, plus the "top N per group" pattern |
| `02-ctes.sql` | Basic and multi-CTE queries, recursive CTE (org chart), date-series generation |
| `03-indexing.sql` | When to index, covering indexes with `INCLUDE`, composite index order, fragmentation check |
| `04-performance-queries.sql` | Slowest-query and missing-index DMVs, sargable vs non-sargable predicates, `SELECT *` and `LIKE` pitfalls |
| `05-date-handling.sql` | Sargable date ranges, correct full-years tenure (watch the `DATEDIFF(YEAR)` trap), grouping by month, `EOMONTH` |
| `06-transactions-error-handling.sql` | All-or-nothing updates, savepoints for partial rollback, the `TRY/CATCH` + `XACT_ABORT` template, `@@TRANCOUNT` nesting gotcha |

## How to run

Open the folder in SQL Server Management Studio (SSMS) or Azure Data Studio, connect to your SQL Server instance, and execute `00-setup-sample-data.sql` first, then any script after it.

## Notes

- All scripts are read-only except `00` (setup) and `03` (creates example indexes). Script `06` writes only to a `#temp` scratch table, so the sample data is never modified.
- The `RANK` vs `DENSE_RANK` demo in `01` relies on two employees sharing the same salary — that tie is intentional in the seed data.
- DMV queries in `04` need `VIEW SERVER STATE` permission on a real server.
