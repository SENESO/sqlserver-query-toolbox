-- ============================================================================
-- 05 - Date handling
-- ----------------------------------------------------------------------------
-- The date patterns you will actually use: ranges, tenure, grouping by month,
-- first/last day of month. Run 00-setup-sample-data.sql first.
-- ============================================================================

-- 1) "Now" functions: GETDATE (local, datetime), SYSDATETIME (local, precise),
--    GETUTCDATE (UTC). Store UTC, convert for display.
SELECT GETDATE() AS LocalNow,
       SYSDATETIME() AS LocalNowPrecise,
       GETUTCDATE() AS UtcNow;

-- 2) Sargable date ranges (index-friendly). Never wrap the column in a function.

-- Last 30 days of sales:
SELECT SaleId, SaleDate, Amount
FROM dbo.Sales
WHERE SaleDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE));

-- Current month:
SELECT SaleId, SaleDate, Amount
FROM dbo.Sales
WHERE SaleDate >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
  AND SaleDate <  DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));

-- Year to date:
SELECT SaleId, SaleDate, Amount
FROM dbo.Sales
WHERE SaleDate >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1);

-- 3) Tenure: full years and total months since hire.
SELECT FirstName,
       LastName,
       HireDate,
       DATEDIFF(YEAR, HireDate, GETDATE()) AS TenureYears,
       DATEDIFF(MONTH, HireDate, GETDATE()) AS TenureMonths
FROM dbo.Employees
ORDER BY HireDate;

-- 4) Group sales by month. DATEFROMPARTS normalizes every date to the 1st,
--    which groups cleanly. (FORMAT() looks nicer but is much slower.)
SELECT DATEFROMPARTS(YEAR(SaleDate), MONTH(SaleDate), 1) AS SaleMonth,
       COUNT(*) AS SalesCount,
       SUM(Amount) AS TotalAmount
FROM dbo.Sales
GROUP BY YEAR(SaleDate), MONTH(SaleDate)
ORDER BY SaleMonth;

-- 5) First and last day of the current month.
SELECT DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS FirstOfMonth,
       EOMONTH(GETDATE()) AS LastOfMonth;

-- 6) Readable parts without FORMAT(): DATENAME for names, DATEPART for numbers.
SELECT FirstName,
       LastName,
       HireDate,
       DATENAME(WEEKDAY, HireDate) AS HiredWeekday,
       DATEPART(QUARTER, HireDate) AS HiredQuarter
FROM dbo.Employees;
