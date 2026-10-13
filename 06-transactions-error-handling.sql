-- ============================================================================
-- 06 - Transactions and error handling
-- ----------------------------------------------------------------------------
-- The patterns that keep multi-statement writes correct: all-or-nothing
-- atomicity, partial rollbacks with savepoints, and the TRY/CATCH template
-- every data-writing stored procedure should use.
-- Run 00-setup-sample-data.sql first. This script only touches a #temp
-- scratch table, so the sample data is never modified.
-- ============================================================================

-- Scratch copy of Employees: every demo below runs against this, so the real
-- tables stay exactly as 00 left them. #temp tables vanish when you disconnect.
SELECT EmployeeId, FirstName, LastName, DepartmentId, Salary
INTO #SalaryDemo
FROM dbo.Employees;
GO

-- 1) THE TEMPLATE — paste this into every stored procedure that writes data.
--    SET XACT_ABORT ON makes SQL Server roll back the whole transaction on
--    most runtime errors. Without it, some errors leave the transaction open
--    and the CATCH block can't clean up reliably.
/*
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    -- ... your INSERT / UPDATE / DELETE statements ...
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    -- XACT_STATE():  1 = committable, -1 = doomed (must roll back),
    --                0 = no transaction open.
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;  -- rethrow the original error to the caller, unchanged
END CATCH
*/

-- 2) All-or-nothing: give everyone a 10% raise, but roll back EVERYTHING if
--    any salary would break the 95000 cap. Ahmed (90000 -> 99000) trips it.
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE #SalaryDemo
    SET Salary = Salary * 1.10;

    IF EXISTS (SELECT 1 FROM #SalaryDemo WHERE Salary > 95000)
        THROW 50001, 'Raise would push a salary over the 95000 cap - rolling back everything.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT ERROR_MESSAGE() AS CaughtError;
END CATCH;
GO

-- Prove it: nobody got the raise — the whole statement was undone.
SELECT FirstName, LastName, Salary
FROM #SalaryDemo
ORDER BY EmployeeId;
GO

-- 3) Savepoints: roll back PART of a transaction, keep the rest.
--    Engineering gets its 10% raise; the Sales step violates the 70000 cap
--    (Sara 65000 -> 71500), so only the Sales step is undone.
BEGIN TRY
    BEGIN TRANSACTION;

    -- Step 1 (kept):
    UPDATE #SalaryDemo
    SET Salary = Salary * 1.10
    WHERE DepartmentId = 1;  -- Engineering

    SAVE TRANSACTION BeforeSalesRaise;

    -- Step 2 (undone on failure):
    UPDATE #SalaryDemo
    SET Salary = Salary * 1.10
    WHERE DepartmentId = 2;  -- Sales

    IF EXISTS (SELECT 1 FROM #SalaryDemo WHERE DepartmentId = 2 AND Salary > 70000)
        THROW 50002, 'Sales salaries would exceed the 70000 cap - rolling back only the Sales step.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        -- Rolls back to the savepoint only; @@TRANCOUNT stays 1, so we can
        -- still COMMIT the Engineering raise that succeeded.
        ROLLBACK TRANSACTION BeforeSalesRaise;
        COMMIT TRANSACTION;
    END
    SELECT ERROR_MESSAGE() AS CaughtError;
END CATCH;
GO

-- Verify: Engineering raised, Sales untouched.
SELECT FirstName, LastName, DepartmentId, Salary
FROM #SalaryDemo
ORDER BY DepartmentId, EmployeeId;
GO

-- 4) @@TRANCOUNT gotcha: transactions don't truly nest.
--    An inner COMMIT only decrements the counter — nothing is committed until
--    the outermost COMMIT. But ANY rollback undoes everything and resets the
--    counter to 0.
BEGIN TRANSACTION;          -- @@TRANCOUNT = 1
    BEGIN TRANSACTION;      -- @@TRANCOUNT = 2 (looks nested, isn't really)
    COMMIT TRANSACTION;     -- @@TRANCOUNT = 1 (nothing committed yet!)
SELECT @@TRANCOUNT AS OpenTransactions;  -- 1: still one transaction open
ROLLBACK TRANSACTION;       -- everything undone, @@TRANCOUNT = 0
GO
-- Practical rule: in nested procedures, only the outermost caller should own
-- COMMIT/ROLLBACK; inner procedures just do their writes (or use savepoints).
