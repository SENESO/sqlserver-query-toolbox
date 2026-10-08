-- ============================================================================
-- 00 - Sample data setup
-- ----------------------------------------------------------------------------
-- Creates the small HR/Sales schema used by every other script in this toolbox.
-- Run this script ONCE before running the others.
--
-- Tables:
--   Departments (DepartmentId, DepartmentName)
--   Employees    (EmployeeId, FirstName, LastName, DepartmentId, Salary,
--                 HireDate, ManagerId -> self reference for org hierarchy)
--   Sales        (SaleId, EmployeeId, SaleDate, Amount)
-- ============================================================================

IF OBJECT_ID('dbo.Sales', 'U') IS NOT NULL DROP TABLE dbo.Sales;
IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL DROP TABLE dbo.Employees;
IF OBJECT_ID('dbo.Departments', 'U') IS NOT NULL DROP TABLE dbo.Departments;
GO

CREATE TABLE dbo.Departments (
    DepartmentId   INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(50) NOT NULL
);

CREATE TABLE dbo.Employees (
    EmployeeId   INT IDENTITY(1,1) PRIMARY KEY,
    FirstName    NVARCHAR(50) NOT NULL,
    LastName     NVARCHAR(50) NOT NULL,
    DepartmentId INT NOT NULL REFERENCES dbo.Departments(DepartmentId),
    Salary       DECIMAL(10,2) NOT NULL,
    HireDate     DATE NOT NULL,
    ManagerId    INT NULL REFERENCES dbo.Employees(EmployeeId)
);

CREATE TABLE dbo.Sales (
    SaleId     INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeId INT NOT NULL REFERENCES dbo.Employees(EmployeeId),
    SaleDate   DATE NOT NULL,
    Amount     DECIMAL(10,2) NOT NULL
);
GO

INSERT INTO dbo.Departments (DepartmentName) VALUES
    ('Engineering'),
    ('Sales'),
    ('HR');

-- ManagerId builds a 3-level hierarchy. Mona and Omar share the same salary
-- on purpose, to demonstrate RANK vs DENSE_RANK ties in script 01.
INSERT INTO dbo.Employees (FirstName, LastName, DepartmentId, Salary, HireDate, ManagerId) VALUES
    ('Ahmed', 'Hassan',  1, 90000.00, '2020-01-15', NULL),  -- 1: top of hierarchy
    ('Mona',  'Ali',     1, 70000.00, '2021-03-10', 1),     -- 2
    ('Omar',  'Khaled',  1, 70000.00, '2021-06-01', 1),     -- 3 (tie with Mona)
    ('Sara',  'Mahmoud', 2, 65000.00, '2020-09-20', 1),     -- 4
    ('Karim', 'Adel',    2, 50000.00, '2022-02-14', 4),     -- 5
    ('Heba',  'Samy',    2, 52000.00, '2022-05-30', 4),     -- 6
    ('Tarek', 'Nour',    3, 55000.00, '2021-11-11', 1),     -- 7
    ('Dina',  'Fathy',   3, 42000.00, '2023-01-09', 7);     -- 8

INSERT INTO dbo.Sales (EmployeeId, SaleDate, Amount) VALUES
    (4, '2024-01-12', 1500.00),
    (5, '2024-01-20', 2300.00),
    (4, '2024-02-05', 1800.00),
    (6, '2024-02-18', 3100.00),
    (5, '2024-03-02', 1200.00),
    (4, '2024-03-15', 2700.00),
    (6, '2024-04-09', 1900.00),
    (5, '2024-04-22', 3400.00),
    (4, '2025-01-10', 2100.00),
    (6, '2025-02-14', 2600.00);
GO

SELECT 'Setup complete.' AS Status,
       (SELECT COUNT(*) FROM dbo.Employees) AS Employees,
       (SELECT COUNT(*) FROM dbo.Sales) AS Sales;
