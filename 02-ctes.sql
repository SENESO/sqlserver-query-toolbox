-- ============================================================================
-- 02 - CTEs: non-recursive and recursive
-- ----------------------------------------------------------------------------
-- A CTE (Common Table Expression) is a named temporary result set defined with
-- WITH. It makes complex queries readable and is required for recursion.
-- Run 00-setup-sample-data.sql first.
-- ============================================================================

-- 1) Basic CTE: employees earning above their department's average salary.
WITH DeptAvg AS (
    SELECT DepartmentId, AVG(Salary) AS AvgSalary
    FROM dbo.Employees
    GROUP BY DepartmentId
)
SELECT e.FirstName, e.LastName, e.Salary, d.AvgSalary
FROM dbo.Employees e
JOIN DeptAvg d ON d.DepartmentId = e.DepartmentId
WHERE e.Salary > d.AvgSalary
ORDER BY e.Salary DESC;

-- 2) Multiple CTEs in one WITH: monthly sales totals, then the best month.
WITH MonthlySales AS (
    SELECT
        DATEFROMPARTS(YEAR(SaleDate), MONTH(SaleDate), 1) AS SaleMonth,
        SUM(Amount) AS TotalAmount
    FROM dbo.Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate)
),
RankedMonths AS (
    SELECT SaleMonth, TotalAmount,
           RANK() OVER (ORDER BY TotalAmount DESC) AS MonthRank
    FROM MonthlySales
)
SELECT SaleMonth, TotalAmount
FROM RankedMonths
WHERE MonthRank = 1;

-- 3) Recursive CTE: walk the employee/manager hierarchy (org chart).
--    Anchor member selects the top level; recursive member joins back to the CTE.
--    Level 0 = Ahmed (no manager), Level 1 = his direct reports, and so on.
WITH OrgChart AS (
    -- Anchor: employees with no manager
    SELECT EmployeeId, FirstName, LastName, ManagerId, 0 AS Level
    FROM dbo.Employees
    WHERE ManagerId IS NULL

    UNION ALL

    -- Recursive: employees whose manager is already in the CTE
    SELECT e.EmployeeId, e.FirstName, e.LastName, e.ManagerId, o.Level + 1
    FROM dbo.Employees e
    JOIN OrgChart o ON o.EmployeeId = e.ManagerId
)
SELECT
    REPLICATE('  ', Level) + FirstName + ' ' + LastName AS OrgTree,
    Level
FROM OrgChart
ORDER BY Level, LastName;
-- NOTE: default recursion limit is 100 levels. For deeper hierarchies add:
-- OPTION (MAXRECURSION 1000);

-- 4) Recursive CTE, different use: generate a date series (last 10 days).
--    Handy for filling gaps in reports (days with zero sales still show up).
WITH DateSeries AS (
    SELECT CAST(GETDATE() AS DATE) AS DayDate
    UNION ALL
    SELECT DATEADD(DAY, -1, DayDate)
    FROM DateSeries
    WHERE DayDate > DATEADD(DAY, -9, CAST(GETDATE() AS DATE))
)
SELECT DayDate
FROM DateSeries
ORDER BY DayDate
OPTION (MAXRECURSION 10);
