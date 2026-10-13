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

-- 3) Tenure: FULL years since hire.
--    CAREFUL — this is the classic DATEDIFF trap: DATEDIFF(YEAR, ...) counts
--    year *boundaries* crossed, not completed years. Someone hired on
--    2021-11-11 shows DATEDIFF(YEAR) = 5 in Oct 2026, but their 5th work
--    anniversary hasn't happened yet — they have only completed 4 full years.
--    The CASE below subtracts 1 when this year's anniversary is still ahead.
SELECT FirstName,
       LastName,
       HireDate,
       DATEDIFF(YEAR, HireDate, CAST(GETDATE() AS DATE)) AS CalendarYearDiff,
       DATEDIFF(YEAR, HireDate, CAST(GETDATE() AS DATE))
         - CASE
               WHEN DATEADD(YEAR,
                            DATEDIFF(YEAR, HireDate, CAST(GETDATE() AS DATE)),
                            HireDate) > CAST(GETDATE() AS DATE)
               THEN 1
               ELSE 0
           END AS TenureFullYears,
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
