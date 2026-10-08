-- ============================================================================
-- 01 - Window functions: ROW_NUMBER, RANK, DENSE_RANK, NTILE
-- ----------------------------------------------------------------------------
-- Window functions compute a value across a set of rows related to the current
-- row, without collapsing them into one row like GROUP BY does.
-- All four functions below need an ORDER BY inside OVER() to define the ranking.
-- Run 00-setup-sample-data.sql first.
-- ============================================================================

-- 1) ROW_NUMBER: unique sequential number per department, highest salary first.
--    Ties still get different numbers (1, 2, 3...). Use it for "top N per group".
SELECT
    FirstName,
    LastName,
    DepartmentId,
    Salary,
    ROW_NUMBER() OVER (PARTITION BY DepartmentId ORDER BY Salary DESC) AS SalaryRank
FROM dbo.Employees
ORDER BY DepartmentId, SalaryRank;

-- 2) RANK vs DENSE_RANK: how they handle ties.
--    Mona and Omar both earn 70000 in Engineering, so watch the difference:
--    RANK leaves a gap after the tie (1, 2, 2, 4), DENSE_RANK does not (1, 2, 2, 3).
SELECT
    FirstName,
    LastName,
    Salary,
    RANK()       OVER (ORDER BY Salary DESC) AS Rnk,
    DENSE_RANK() OVER (ORDER BY Salary DESC) AS DenseRnk
FROM dbo.Employees
ORDER BY Salary DESC;

-- 3) NTILE: split rows into N roughly equal buckets.
--    Here: salary quartiles across the whole company (1 = top 25%).
SELECT
    FirstName,
    LastName,
    Salary,
    NTILE(4) OVER (ORDER BY Salary DESC) AS SalaryQuartile
FROM dbo.Employees
ORDER BY Salary DESC;

-- 4) Practical pattern: top 2 earners per department.
--    Window functions can't go in WHERE directly, so wrap in a subquery.
SELECT FirstName, LastName, DepartmentId, Salary
FROM (
    SELECT
        FirstName,
        LastName,
        DepartmentId,
        Salary,
        ROW_NUMBER() OVER (PARTITION BY DepartmentId ORDER BY Salary DESC) AS rn
    FROM dbo.Employees
) ranked
WHERE rn <= 2
ORDER BY DepartmentId, Salary DESC;
