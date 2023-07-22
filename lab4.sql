use AdventureWorks2012;
go
drop procedure if exists dbo.GetMaxDiscountsByCategory
go

CREATE PROCEDURE dbo.GetMaxDiscountsByCategory
    @categories NVARCHAR(MAX)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'SELECT Category, ' + @categories +
               N'FROM (SELECT so.Category AS Product, so.DiscountPct as Discount, p.Name AS Category
                      FROM Sales.SpecialOffer so
					  join Sales.SpecialOfferProduct sop on so.SpecialOfferID=sop.SpecialOfferID
                      JOIN Production.Product p ON sop.ProductID = p.ProductID
                      ) AS SourceTable
               PIVOT (max(Discount) FOR Product IN (' + @categories + N')) AS PivotTable;';

    EXEC sp_executesql @sql;
END;
go

EXECUTE dbo.GetMaxDiscountsByCategory '[Reseller], [No Discount], [Customer]';

go

DECLARE @xml XML;

SELECT @xml = (
  SELECT 
    [StartDate] AS 'Transaction/Start',
    [GroupName] AS 'Transaction/Department/Group',
    [Name] AS 'Transaction/Department/Name'
  FROM [HumanResources].[EmployeeDepartmentHistory] edh
  JOIN [HumanResources].[Department] d ON edh.[DepartmentID] = d.[DepartmentID]
  FOR XML PATH(''), ROOT('History')
);

SELECT @xml;

CREATE TABLE #temp (Department XML);

INSERT INTO #temp (Department) 
SELECT x.Department.query('Department') 
FROM (SELECT CAST(@xml AS XML) AS DepartmentXml) AS t 
CROSS APPLY t.DepartmentXml.nodes('/History/Transaction') x(Department);

SELECT * FROM #temp;

DROP TABLE #temp;
go

DECLARE @xml XML =
(
SELECT [BusinessEntityID] AS ID, [FirstName], [LastName]
FROM [Person].[Person]
FOR XML PATH('Person'), ROOT('Persons')
);

CREATE TABLE #temp (Persons XML);
INSERT INTO #temp (Persons) VALUES (@xml);


SELECT * FROM #temp;

DROP TABLE #temp;
go