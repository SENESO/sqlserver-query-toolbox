-- ============================================================================
-- 04 - Performance: find slow queries and missing indexes
-- ----------------------------------------------------------------------------
-- Diagnostic queries against SQL Server DMVs plus the most common query
-- anti-patterns. Some DMVs need VIEW SERVER STATE permission.
-- Run 00-setup-sample-data.sql first (the demo queries at the bottom need it).
-- ============================================================================

-- 1) Top 10 slowest queries by total CPU since the last restart.
--    Run this on the real server, not on the sample database.
SELECT TOP 10
    qs.total_worker_time / 1000 AS TotalCpuMs,
    qs.execution_count AS Executions,
    (qs.total_worker_time / 1000) / NULLIF(qs.execution_count, 0) AS AvgCpuMs,
    SUBSTRING(st.text, 1, 200) AS QueryPreview
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_worker_time DESC;

-- 2) Missing indexes SQL Server is asking for, ordered by potential impact.
SELECT TOP 10
    migs.avg_total_user_cost * migs.avg_user_impact *
        (migs.user_seeks + migs.user_scans) AS ImpactScore,
    mid.statement AS TableName,
    mid.equality_columns AS EqualityColumns,
    mid.inequality_columns AS InequalityColumns,
    mid.included_columns AS IncludedColumns
FROM sys.dm_db_missing_index_group_stats migs
JOIN sys.dm_db_missing_index_groups mig
    ON mig.index_group_handle = migs.group_handle
JOIN sys.dm_db_missing_index_details mid
    ON mid.index_handle = mig.index_handle
ORDER BY ImpactScore DESC;
-- NOTE: don't create these blindly — validate against your real workload first.

-- 3) SARGABLE vs NON-SARGABLE: the #1 beginner performance mistake.
--    Wrapping an indexed column in a function prevents index seeks.

-- BAD: function on the column -> full scan even with an index on HireDate.
SELECT FirstName, LastName
FROM dbo.Employees
WHERE YEAR(HireDate) = 2022;

-- GOOD: date range -> index seek.
SELECT FirstName, LastName
FROM dbo.Employees
WHERE HireDate >= '2022-01-01'
  AND HireDate <  '2023-01-01';

-- 4) See what SQL Server actually does: logical reads per query.
--    Lower logical reads = less work. Compare before/after adding an index.
SET STATISTICS IO, TIME ON;
GO
SELECT FirstName, LastName, Salary
FROM dbo.Employees
WHERE DepartmentId = 2;
GO
SET STATISTICS IO, TIME OFF;
GO

-- 5) Avoid SELECT * in application code: it pulls unneeded columns (and breaks
--    covering indexes) and couples you to every future schema change.
-- BAD:  SELECT * FROM dbo.Employees WHERE DepartmentId = 2;
-- GOOD:
SELECT EmployeeId, FirstName, LastName, Salary
FROM dbo.Employees
WHERE DepartmentId = 2;

-- 6) LIKE patterns: 'abc%' can seek an index, '%abc' never can.
-- Seeks:
SELECT FirstName, LastName FROM dbo.Employees WHERE LastName LIKE 'A%';
-- Scans (leading wildcard):
-- SELECT FirstName, LastName FROM dbo.Employees WHERE LastName LIKE '%a';
