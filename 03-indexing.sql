-- ============================================================================
-- 03 - Indexing best practices
-- ----------------------------------------------------------------------------
-- Indexes make reads fast and writes slower. The rules below cover 90% of
-- real-world cases. Run 00-setup-sample-data.sql first.
--
-- QUICK MENTAL MODEL:
--   - Clustered index  = the table itself, sorted (one per table, usually the PK).
--   - Nonclustered index = a separate lookup structure pointing at rows.
--   - Covering index    = a nonclustered index that contains every column the
--                         query needs (via INCLUDE), so the table is never touched.
-- ============================================================================

-- 1) Index the columns you filter, join, and sort on.
--    These queries filter by DepartmentId and join on it constantly:
CREATE NONCLUSTERED INDEX IX_Employees_DepartmentId
    ON dbo.Employees (DepartmentId);

-- 2) Covering index with INCLUDE: the query below needs Salary too, but Salary
--    is never filtered on — INCLUDE keeps it in the leaf pages without
--    bloating the index key.
CREATE NONCLUSTERED INDEX IX_Employees_DepartmentId_Salary
    ON dbo.Employees (DepartmentId)
    INCLUDE (Salary);

-- This query is now fully served by the index above (no table lookup):
SELECT FirstName, LastName, Salary
FROM dbo.Employees
WHERE DepartmentId = 2;

-- 3) Composite index order matters: put the most selective / most-queried
--    column first, and match the ORDER BY direction your queries use.
CREATE NONCLUSTERED INDEX IX_Sales_EmployeeId_SaleDate
    ON dbo.Sales (EmployeeId, SaleDate DESC);

-- 4) Inspect what exists on a table before adding more:
SELECT i.name AS IndexName,
       i.type_desc AS IndexType,
       i.is_unique AS IsUnique,
       STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
FROM sys.indexes i
JOIN sys.index_columns ic
    ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c
    ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID('dbo.Employees')
GROUP BY i.name, i.type_desc, i.is_unique;

-- 5) Check fragmentation: > 30% on a large index = consider REBUILD.
SELECT OBJECT_NAME(ips.object_id) AS TableName,
       i.name AS IndexName,
       ips.avg_fragmentation_in_percent AS FragmentationPct,
       ips.page_count AS Pages
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i
    ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE ips.page_count > 10;

-- 6) WHAT NOT TO DO (commented out on purpose):
--
-- -- Don't index every column "just in case": each index slows down
-- -- INSERT/UPDATE/DELETE and costs disk space.
-- -- CREATE NONCLUSTERED INDEX IX_Employees_Everything ON dbo.Employees (FirstName, LastName, Salary, HireDate);
--
-- -- Don't index tiny lookup tables (a 3-row Departments table is scanned
-- -- faster than any index lookup).
--
-- -- Don't lead a composite index with a low-selectivity column alone
-- -- (e.g. a Gender column with 2 values) unless queries always filter on it
-- -- together with the other columns.
