USE HeartEnterpriseDB;
GO

-- =============================================
-- 1. Patients Table
-- =============================================
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY,
    Age TINYINT NOT NULL,
    AgeDistribution NVARCHAR(50) NOT NULL,
    Gender NVARCHAR(50) NOT NULL,
    Height TINYINT NOT NULL,
    Weight TINYINT NOT NULL
);
GO

-- =============================================
-- 2. HealthMetrics Table
-- =============================================
CREATE TABLE HealthMetrics (
    MetricID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    Cholesterol NVARCHAR(50) NOT NULL,
    Glucose NVARCHAR(50) NOT NULL,
    BMI FLOAT NOT NULL,
    BMIClass NVARCHAR(50) NOT NULL,
    ApHi SMALLINT NOT NULL,
    ApLo SMALLINT NOT NULL,
    BloodPressure NVARCHAR(50) NOT NULL,

    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);
GO

-- =============================================
-- 3. Lifestyle Table
-- =============================================
CREATE TABLE Lifestyle (
    LifestyleID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    Smoke NVARCHAR(50) NOT NULL,
    Alcohol NVARCHAR(50) NOT NULL,
    Activity NVARCHAR(50) NOT NULL,

    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);
GO

-- =============================================
-- 4. RiskClassification Table
-- =============================================
CREATE TABLE RiskClassification (
    RiskID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    BPClass NVARCHAR(50) NOT NULL,
    CVD NVARCHAR(50) NOT NULL,

    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);
GO
-------------------------------
--SELECTIONNNNNNNNNNNNNN
-------------------------------
USE HeartEnterpriseDB;
GO

-- =============================================
-- Insert into Patients
-- =============================================
INSERT INTO Patients (
    PatientID,
    Age,
    AgeDistribution,
    Gender,
    Height,
    Weight
)
SELECT
    id,
    age,
    age_distribution,
    gender,
    height,
    weight
FROM HeartData_Raw;
GO


-- =============================================
-- Insert into HealthMetrics
-- =============================================
INSERT INTO HealthMetrics (
    PatientID,
    Cholesterol,
    Glucose,
    BMI,
    BMIClass,
    ApHi,
    ApLo,
    BloodPressure
)
SELECT
    id,
    cholesterol,
    gluc,
    BMI,
    BMI_Class,
    ap_hi,
    ap_lo,
    [Blood_pressure]
FROM HeartData_Raw;
GO


-- =============================================
-- Insert into Lifestyle
-- =============================================
INSERT INTO Lifestyle (
    PatientID,
    Smoke,
    Alcohol,
    Activity
)
SELECT
    id,
    smoke,
    alco,
    active
FROM HeartData_Raw;
GO


-- =============================================
-- Insert into RiskClassification
-- =============================================
INSERT INTO RiskClassification (
    PatientID,
    BPClass,
    CVD
)
SELECT
    id,
    BP_Class,
    CVD
FROM HeartData_Raw;
GO


USE HeartEnterpriseDB;
GO

SELECT 
    'Patients' AS TableName,
    COUNT(*) AS TotalRows
FROM dbo.Patients

UNION ALL

SELECT 
    'HealthMetrics' AS TableName,
    COUNT(*) AS TotalRows
FROM dbo.HealthMetrics

UNION ALL

SELECT 
    'Lifestyle' AS TableName,
    COUNT(*) AS TotalRows
FROM dbo.Lifestyle

UNION ALL

SELECT 
    'RiskClassification' AS TableName,
    COUNT(*) AS TotalRows
FROM dbo.RiskClassification;
GO
----------------------------
--Joinnnnn
----------------------------
USE HeartEnterpriseDB;
GO

SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id;
GO
----------------------------------
--Multi-Table JOIN Query
----------------------------------
USE HeartEnterpriseDB;
GO

SELECT TOP 100
    p.PatientID,
    p.Age,
    p.AgeDistribution,
    p.Gender,
    p.Height,
    p.Weight,

    hm.Cholesterol,
    hm.Glucose,
    hm.BMI,
    hm.BMIClass,
    hm.ApHi,
    hm.ApLo,
    hm.BloodPressure,

    l.Smoke,
    l.Alcohol,
    l.Activity,

    rc.BPClass,
    rc.CVD

FROM dbo.Patients AS p

INNER JOIN dbo.HealthMetrics AS hm
    ON p.PatientID = hm.PatientID

INNER JOIN dbo.Lifestyle AS l
    ON p.PatientID = l.PatientID

INNER JOIN dbo.RiskClassification AS rc
    ON p.PatientID = rc.PatientID;
GO
---------------------------------
--Conditional Grouping + Aggregation
---------------------------------
USE HeartEnterpriseDB;
GO

SELECT
    CASE
        WHEN rc.CVD = 'cvd' THEN 'High Risk'
        WHEN hm.BMI >= 30 THEN 'Medium Risk'
        WHEN hm.Cholesterol IN ('high', 'elevated') THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS RiskGroup,

    p.Gender,

    COUNT(*) AS PatientCount,

    ROUND(AVG(hm.BMI), 2) AS AvgBMI,

    ROUND(AVG(CAST(hm.ApHi AS FLOAT)), 2) AS AvgSystolicBP

FROM dbo.Patients AS p

INNER JOIN dbo.HealthMetrics AS hm
    ON p.PatientID = hm.PatientID

INNER JOIN dbo.Lifestyle AS l
    ON p.PatientID = l.PatientID

INNER JOIN dbo.RiskClassification AS rc
    ON p.PatientID = rc.PatientID

GROUP BY
    CASE
        WHEN rc.CVD = 'cvd' THEN 'High Risk'
        WHEN hm.BMI >= 30 THEN 'Medium Risk'
        WHEN hm.Cholesterol IN ('high', 'elevated') THEN 'Medium Risk'
        ELSE 'Low Risk'
    END,
    p.Gender

ORDER BY RiskGroup, PatientCount DESC;
GO
--------------------------------------------------
--Modular Database Views for Business Intelligence(vw_PatientHealthSummary)
--------------------------------------------------
USE HeartEnterpriseDB;
GO

CREATE VIEW dbo.vw_PatientHealthSummary
AS
SELECT
    p.PatientID,
    p.Age,
    p.AgeDistribution,
    p.Gender,
    p.Height,
    p.Weight,

    hm.Cholesterol,
    hm.Glucose,
    hm.BMI,
    hm.BMIClass,
    hm.ApHi AS SystolicBP,
    hm.ApLo AS DiastolicBP,
    hm.BloodPressure,

    l.Smoke,
    l.Alcohol,
    l.Activity,

    rc.BPClass,
    rc.CVD,

    CASE
        WHEN rc.CVD = 'cvd' THEN 'High Risk'
        WHEN hm.BMI >= 30 THEN 'Medium Risk'
        WHEN hm.Cholesterol IN ('high', 'elevated') THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS RiskGroup

FROM dbo.Patients AS p
INNER JOIN dbo.HealthMetrics AS hm
    ON p.PatientID = hm.PatientID
INNER JOIN dbo.Lifestyle AS l
    ON p.PatientID = l.PatientID
INNER JOIN dbo.RiskClassification AS rc
    ON p.PatientID = rc.PatientID;
GO

SELECT TOP 100 *
FROM dbo.vw_PatientHealthSummary;
GO
--------------------------------
--View 2: Risk Analysis
--------------------------------
USE HeartEnterpriseDB;
GO

CREATE VIEW dbo.vw_RiskAnalysis
AS
SELECT
    CASE
        WHEN rc.CVD = 'cvd' THEN 'High Risk'
        WHEN hm.BMI >= 30 THEN 'Medium Risk'
        WHEN hm.Cholesterol IN ('high', 'elevated') THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS RiskGroup,

    p.Gender,

    COUNT(*) AS PatientCount,

    ROUND(AVG(hm.BMI), 2) AS AvgBMI,

    ROUND(AVG(CAST(hm.ApHi AS FLOAT)), 2) AS AvgSystolicBP

FROM dbo.Patients AS p

INNER JOIN dbo.HealthMetrics AS hm
    ON p.PatientID = hm.PatientID

INNER JOIN dbo.RiskClassification AS rc
    ON p.PatientID = rc.PatientID

GROUP BY
    CASE
        WHEN rc.CVD = 'cvd' THEN 'High Risk'
        WHEN hm.BMI >= 30 THEN 'Medium Risk'
        WHEN hm.Cholesterol IN ('high', 'elevated') THEN 'Medium Risk'
        ELSE 'Low Risk'
    END,
    p.Gender;
GO
SELECT *
FROM dbo.vw_RiskAnalysis;
GO
----------------------------
--View 3: Lifestyle Analysis
----------------------------
USE HeartEnterpriseDB;
GO

CREATE VIEW dbo.vw_LifestyleAnalysis
AS
SELECT
    l.Smoke,
    l.Alcohol,
    l.Activity,
    rc.CVD,

    COUNT(*) AS PatientCount,

    ROUND(AVG(hm.BMI), 2) AS AvgBMI,

    ROUND(AVG(CAST(hm.ApHi AS FLOAT)), 2) AS AvgSystolicBP

FROM dbo.Lifestyle AS l

INNER JOIN dbo.HealthMetrics AS hm
    ON l.PatientID = hm.PatientID

INNER JOIN dbo.RiskClassification AS rc
    ON l.PatientID = rc.PatientID

GROUP BY
    l.Smoke,
    l.Alcohol,
    l.Activity,
    rc.CVD;
GO
SELECT *
FROM dbo.vw_LifestyleAnalysis;
GO
--------------------------------------------
--PatientTerritory (Security Mapping Table )
--------------------------------------------
USE HeartEnterpriseDB;
GO

CREATE TABLE dbo.PatientTerritory (
    PatientID INT PRIMARY KEY,
    Territory NVARCHAR(50) NOT NULL,

    CONSTRAINT FK_PatientTerritory_Patients
        FOREIGN KEY (PatientID)
        REFERENCES dbo.Patients(PatientID)
);
GO

-- =============================================
-- Assign Patients to Operational Territories
-- Purpose: Create a deterministic territory mapping
-- for patients to support Manager-Based Dynamic RLS
-- =============================================

USE HeartEnterpriseDB;
GO

INSERT INTO dbo.PatientTerritory (PatientID, Territory)
SELECT
    PatientID,
    CASE
        WHEN PatientID % 4 = 0 THEN 'North'
        WHEN PatientID % 4 = 1 THEN 'South'
        WHEN PatientID % 4 = 2 THEN 'East'
        ELSE 'West'
    END AS Territory
FROM dbo.Patients;
GO

SELECT
    Territory,
    COUNT(*) AS PatientCount
FROM dbo.PatientTerritory
GROUP BY Territory
ORDER BY Territory;
GO
-- =============================================
-- Create Manager Territory Access Table
-- Purpose: Define manager access permissions
-- for Dynamic Row-Level Security (RLS)
-- =============================================

USE HeartEnterpriseDB;
GO

CREATE TABLE dbo.UserTerritoryAccess (
    UserEmail NVARCHAR(100) PRIMARY KEY,
    ManagerName NVARCHAR(100) NOT NULL,
    Territory NVARCHAR(50) NOT NULL
);
GO
-- =============================================
-- Insert Manager Territory Access Data
-- Purpose: Map each manager/user to the territory
-- they are authorized to access
-- =============================================

USE HeartEnterpriseDB;
GO

INSERT INTO dbo.UserTerritoryAccess
    (UserEmail, ManagerName, Territory)
VALUES
    ('manager.north@company.com', 'Ahmed Hassan', 'North'),
    ('manager.south@company.com', 'Sara Ali', 'South'),
    ('manager.east@company.com', 'Mohamed Adel', 'East'),
    ('manager.west@company.com', 'Mona Khaled', 'West');
GO
-- =============================================
-- Verify Manager Territory Access Mapping
-- =============================================

SELECT *
FROM dbo.UserTerritoryAccess;
GO