USE AdventureWorks2012;
GO

/*a) добавьте в таблицу dbo.Person поле EmailAddress типа nvarchar размерностью 50 символов;*/
ALTER TABLE dbo.Person 
ADD EmailAddress NVARCHAR(50) NULL;
GO

/*b) объявите табличную переменную с такой же структурой как dbo.Person и заполните ее данными 
из dbo.Person. Поле EmailAddress заполните данными из Person.EmailAddress;*/
DECLARE @Person TABLE(
	BusinessEntityID INT NOT NULL,
	PersonType NCHAR(2) NOT NULL,
	NameStyle BIT NOT NULL,
	Title NVARCHAR(4) NOT NULL,
	FirstName NVARCHAR(50) NOT NULL,
	MiddleName NVARCHAR(50) NULL,
	LastName NVARCHAR(50) NOT NULL,
	Suffix NVARCHAR(10) NULL,
	EmailPromotion INT NOT NULL,
	ModifiedDate DATETIME NOT NULL,
	EmailAddress NVARCHAR(50) NULL,
	PRIMARY KEY (BusinessEntityID, PersonType)
);

INSERT INTO @Person (
	BusinessEntityID, 
	PersonType, 
	NameStyle,
	Title,
	FirstName, 
	MiddleName, 
	LastName , 
	Suffix,
	EmailPromotion, 
	ModifiedDate,
	EmailAddress)
SELECT 
	p.BusinessEntityID,
	p.PersonType,
    p.NameStyle,
	p.Title,
	p.FirstName,
	p.MiddleName,
	p.LastName,
	p.Suffix,
	p.EmailPromotion,
	p.ModifiedDate,
	e.EmailAddress
FROM dbo.Person p
INNER JOIN Person.EmailAddress e ON e.BusinessEntityID = p.BusinessEntityID;

SELECT * FROM @Person;

/*c) обновите поле EmailAddress в dbo.Person данными из табличной переменной, 
убрав из адреса все встречающиеся нули;*/
UPDATE dbo.Person
SET dbo.Person.EmailAddress = REPLACE(p.EmailAddress, '0', '')
FROM @Person AS p;

SELECT EmailAddress FROM dbo.Person;

/*d) удалите данные из dbo.Person, для которых тип контакта в таблице PhoneNumberType равен ‘Work’;*/
DELETE p
FROM dbo.Person p
JOIN Person.PersonPhone pp ON pp.BusinessEntityID = p.BusinessEntityID
JOIN Person.PhoneNumberType pn ON pn.PhoneNumberTypeID = pp.PhoneNumberTypeID
WHERE pn.Name = 'Work';

/*e) удалите поле EmailAddress из таблицы, удалите все созданные ограничения и значения по умолчанию.*/
ALTER TABLE dbo.Person DROP COLUMN EmailAddress
ALTER TABLE dbo.Person DROP CONSTRAINT PK_Person
ALTER TABLE dbo.Person DROP CONSTRAINT CheckType
ALTER TABLE dbo.Person DROP CONSTRAINT DF_Person_Title

/*f) удалите таблицу dbo.Person.*/
DROP TABLE dbo.Person;

/*a) выполните код, созданный во втором задании второй лабораторной работы. 
Добавьте в таблицу dbo.Person поля TotalGroupSales MONEY и SalesYTD MONEY.
Также создайте в таблице вычисляемое поле RoundSales, округляющее значение в поле SalesYTD до целого числа.*/
ALTER TABLE dbo.Person
ADD TotalGroupSales MONEY, SalesYTD MONEY, RoundSales AS (ROUND(SalesYTD, 0));

/*b) создайте временную таблицу #Person, с первичным ключом по полю BusinessEntityID. 
Временная таблица должна включать все поля таблицы dbo.Person за исключением поля RoundSales.*/
CREATE TABLE dbo.#Person (
	BusinessEntityID INT NOT NULL,
	PersonType NCHAR(2) NOT NULL,
	NameStyle BIT NOT NULL,
	Title NVARCHAR(4) NOT NULL,
	FirstName NVARCHAR(50) NOT NULL,
	MiddleName NVARCHAR(50) NULL,
	LastName NVARCHAR(50) NOT NULL,
	Suffix NVARCHAR(10) NULL,
	EmailPromotion INT NOT NULL,
	ModifiedDate DATETIME NOT NULL,
	TotalGroupSales MONEY,
	SalesYTD MONEY
	PRIMARY KEY(BusinessEntityID)
);

/*c) заполните временную таблицу данными из dbo.Person. Поле SalesYTD заполните 
значениями из таблицы Sales.SalesTerritory. Посчитайте общую сумму продаж (SalesYTD) 
для каждой группы территорий (Group) в таблице Sales.SalesTerritory и заполните этими значениями поле 
TotalGroupSales. Подсчет суммы продаж осуществите в Common Table Expression (CTE).*/
WITH SALES_CTE AS (SELECT
	st."Group",
	SUM(st.SalesYTD) TotalGroupSales
FROM Sales.SalesTerritory st
GROUP BY
	st."Group")

INSERT INTO dbo.#Person (
	BusinessEntityID, 
	PersonType, 
	NameStyle,
	Title,
	FirstName, 
	MiddleName, 
	LastName, 
	Suffix,
	EmailPromotion, 
	ModifiedDate,
	TotalGroupSales,
	SalesYTD
) SELECT
	p.BusinessEntityID, 
	p.PersonType, 
	p.NameStyle,
	p.Title,
	p.FirstName, 
	p.MiddleName, 
	p.LastName, 
	p.Suffix,
	p.EmailPromotion, 
	p.ModifiedDate,
	t.TotalGroupSales,
	st.SalesYTD
FROM dbo.Person p
INNER JOIN Sales.Customer c ON c.PersonID = p.BusinessEntityID
INNER JOIN Sales.SalesTerritory st ON st.TerritoryID = c.TerritoryID
INNER JOIN SALES_CTE t ON st."Group" = t."Group";

SELECT * FROM dbo.#Person;

/*d) удалите из таблицы dbo.Person строки, где EmailPromotion = 2*/
DELETE FROM dbo.Person WHERE EmailPromotion = 2;

/*e) напишите Merge выражение, использующее dbo.Person как target,
а временную таблицу как source. Для связи target и source используйте BusinessEntityID. 
Обновите поля TotalGroupSales и SalesYTD, если запись присутствует в source и target. 
Если строка присутствует во временной таблице, но не существует в target, добавьте строку 
в dbo.Person. Если в dbo.Person присутствует такая строка, которой не существует
во временной таблице, удалите строку из dbo.Person.*/
MERGE INTO dbo.Person dest
USING dbo.#Person src
ON dest.BusinessEntityID = src.BusinessEntityID
WHEN MATCHED THEN UPDATE SET 
	dest.TotalGroupSales = src.TotalGroupSales,
	dest.SalesYTD = src.SalesYTD
WHEN NOT MATCHED BY TARGET THEN	INSERT (
	BusinessEntityID, 
	PersonType, 
	NameStyle,
	Title,
	FirstName, 
	MiddleName, 
	LastName, 
	Suffix,
	EmailPromotion, 
	ModifiedDate,
	TotalGroupSales,
	SalesYTD)
VALUES(
	src.BusinessEntityID, 
	src.PersonType, 
	src.NameStyle,
	src.Title,
	src.FirstName, 
	src.MiddleName, 
	src.LastName, 
	src.Suffix,
	src.EmailPromotion, 
	src.ModifiedDate,
	src.TotalGroupSales,
	src.SalesYTD)
WHEN NOT MATCHED BY SOURCE THEN DELETE;
GO

SELECT * FROM dbo.Person;