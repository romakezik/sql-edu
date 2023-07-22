use AdventureWorks2012

drop function if exists GetEmployeeGenderByCity;
go


CREATE FUNCTION GetEmployeeGenderByCity(@gender NVARCHAR(6))
RETURNS TABLE
AS
RETURN 
(
    SELECT *
    FROM (
        SELECT City, Gender, COUNT(*) AS Count
        FROM Person.Address AS A
        JOIN HumanResources.Employee AS E ON E.AddressID = A.AddressID
        GROUP BY City, Gender
    ) AS src
    PIVOT (
        SUM(Count) FOR Gender IN ([Male], [Female])
    ) AS pvt
    WHERE @gender IS NULL OR pvt.[@gender] IS NOT NULL
);
go
SELECT * FROM dbo.GetEmployeeGenderByCity('Male');

----------------------------
Drop  procedure if exists dbo.GetCreditCardsFromXml;
go

CREATE PROCEDURE dbo.GetCreditCardsFromXml
    @xml NVARCHAR(MAX)
AS
BEGIN

    DECLARE @creditCards TABLE
    (
        [CreditCardID] INT,
        [CardType] NVARCHAR(50),
        [CardNumber] NVARCHAR(50)
    );

    INSERT INTO @creditCards ([CreditCardID], [CardType], [CardNumber])
    SELECT
        [CreditCardID] = x.c.value('@ID', 'INT'),
        [CardType] = x.c.value('@Type', 'NVARCHAR(50)'),
        [CardNumber] = x.c.value('@Number', 'NVARCHAR(50)')
    FROM
        (SELECT TRY_CAST(@xml AS XML)) AS src(xml)
    CROSS APPLY
        src.xml.nodes('/CreditCards/Card') AS x(c);

    SELECT [CreditCardID], [CardType], [CardNumber]
    FROM @creditCards;
END;
GO

DECLARE @xml NVARCHAR(MAX) = '
<CreditCards>
    <Card ID="1" Type="SuperiorCard" Number="33332664695310" />
    <Card ID="2" Type="Distinguish" Number="55552127249722" />
</CreditCards>';

EXEC dbo.GetCreditCardsFromXml @xml;
