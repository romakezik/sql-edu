USE [AdventureWorks2012];
Go

/*a) Создайте таблицу Person.PhoneNumberTypeHst, которая будет хранить информацию об изменениях 
в таблице Person.PhoneNumberType. 
Обязательные поля, которые должны присутствовать в таблице: 
ID — первичный ключ IDENTITY(1,1); 
Action — совершенное действие (insert, update или delete); 
ModifiedDate — дата и время, когда была совершена операция; 
SourceID — первичный ключ исходной таблицы; 
UserName — имя пользователя, совершившего операцию. 
Создайте другие поля, если считаете их нужными.*/
CREATE TABLE [Person].[PhoneNumberTypeHst] (
	[ID] INT IDENTITY(1, 1) PRIMARY KEY,
	[Action] CHAR(6) NOT NULL CHECK ([Action] IN('INSERT', 'UPDATE', 'DELETE')),
	[ModifiedDate] DATETIME NOT NULL,
	[SourceID] INT NOT NULL,
	[UserName] VARCHAR(50) NOT NULL
);
go

/*b) Создайте три AFTER триггера для трех операций INSERT, UPDATE, DELETE 
для таблицы Person.PhoneNumberType. Каждый триггер должен заполнять таблицу 
Person.PhoneNumberTypeHst с указанием типа операции в поле Action.*/
CREATE TRIGGER [Person].[PhoneNumberType_InsertTrigger]
ON [Person].[PhoneNumberType]
AFTER INSERT AS
	INSERT INTO [Person].[PhoneNumberTypeHst]([Action], [ModifiedDate], [SourceID], [UserName])
	SELECT 'INSERT', GETDATE(), [ins].[PhoneNumberTypeID], USER_NAME()
	FROM [inserted] AS [ins];
	go

CREATE TRIGGER [Person].[PhoneNumberType_UpdateTrigger]
ON [Person].[PhoneNumberType]
AFTER UPDATE AS
	INSERT INTO [Person].[PhoneNumberTypeHst]([Action], [ModifiedDate], [SourceID], [UserName])
	SELECT 'UPDATE', GETDATE(), [ins].[PhoneNumberTypeID], USER_NAME()
	FROM [inserted] AS [ins];
	go

CREATE TRIGGER [Person].[PhoneNumberType_DeleteTrigger]
ON [Person].[PhoneNumberType]
AFTER DELETE AS
	INSERT INTO [Person].[PhoneNumberTypeHst]([Action], [ModifiedDate], [SourceID], [UserName])
	SELECT 'DELETE', GETDATE(), [ins].[PhoneNumberTypeID], USER_NAME()
	FROM [deleted] AS [ins];
	go

/*c) Создайте представление VIEW, отображающее все поля таблицы 
Person.PhoneNumberType. Сделайте невозможным просмотр исходного кода представления.*/
CREATE VIEW [Person].[PhoneNumberTypeView] 
WITH ENCRYPTION
AS SELECT * FROM [Person].[PhoneNumberType];

/*d) Вставьте новую строку в Person.PhoneNumberType через представление. Обновите вставленную 
строку. Удалите вставленную строку. Убедитесь, что все три операции отображены в Person.PhoneNumberTypeHst.*/
INSERT INTO [Person].[PhoneNumberTypeView]  ([Name], [ModifiedDate])
VALUES ('Name1', GETDATE());

UPDATE [Person].[PhoneNumberTypeView] 
SET [Name] = 'Name2'
WHERE [PhoneNumberTypeID] = (
	SELECT MAX([PhoneNumberTypeID]) 
	FROM [Person].[PhoneNumberTypeView]);

DELETE FROM [Person].[PhoneNumberTypeView] 
WHERE [PhoneNumberTypeID] = (
	SELECT MAX([PhoneNumberTypeID]) 
	FROM [Person].[PhoneNumberTypeView]);

SELECT * FROM [Person].[PhoneNumberTypeHst];

USE [AdventureWorks2012];
GO

/*a) Создайте представление VIEW, отображающее данные из таблиц Person.PhoneNumberType 
и Person.PersonPhone. Создайте уникальный кластерный индекс в представлении 
по полям PhoneNumberTypeID и BusinessEntityID.*/
drop view if exists person.PhoneNumberTypeAndPhoneView;
CREATE VIEW [Person].[PhoneNumberTypeAndPhoneView] (
	[BusinessEntityID],
	[PhoneNumber],
	[PhoneNumberTypeID],
	[Name],
	[PhoneModifiedDate],
	[PhoneNumberTypeModifiedDate]
)
WITH SCHEMABINDING 
AS SELECT 
	[pp].[BusinessEntityID],
	[pp].[PhoneNumber],
	[pnt].[PhoneNumberTypeID],
	[pnt].[Name],
	[pp].[ModifiedDate],
	[pnt].[ModifiedDate]
FROM [Person].[PersonPhone] AS [pp]
INNER JOIN [Person].[PhoneNumberType] AS [pnt] ON [pnt].[PhoneNumberTypeID] = [pp].[PhoneNumberTypeID]
GO

CREATE UNIQUE CLUSTERED INDEX [IX_PhoneNumberTypeAndPhoneView_PhoneNumberTypeID_BusinessEntityID]
ON [Person].[PhoneNumberTypeAndPhoneView] ([PhoneNumberTypeID], [BusinessEntityID])
GO

/*b) Создайте один INSTEAD OF триггер для представления на три операции INSERT, UPDATE, DELETE. 
Триггер должен выполнять соответствующие операции в таблицах Person.PhoneNumberType и Person.PersonPhone 
для указанного BusinessEntityID.*/
CREATE TRIGGER [Person].[PhoneNumberTypeAndPhoneViewInsertUpdateDeleteTrigger] 
ON [Person].[PhoneNumberTypeAndPhoneView]
INSTEAD OF INSERT, UPDATE, DELETE AS
BEGIN
	IF EXISTS (SELECT * FROM [inserted])
	BEGIN
		IF NOT EXISTS (SELECT * FROM [deleted])
		BEGIN
			/*insert*/
			INSERT INTO [Person].[PhoneNumberType] (
				[Name],
				[ModifiedDate])
			SELECT 
				[inserted].[Name],
				GETDATE()
			FROM [inserted]
	
			INSERT INTO [Person].[PersonPhone] (
				[BusinessEntityID],
				[PhoneNumber],
				[PhoneNumberTypeID],
				[ModifiedDate])
			SELECT 
				[inserted].[BusinessEntityID],
				[inserted].[PhoneNumber],
				[pnt].[PhoneNumberTypeID],
				GETDATE()
			FROM [inserted]
			INNER JOIN [Person].[PhoneNumberType] [pnt] ON [pnt].[Name] = [inserted].[Name];
		END
		ELSE
		BEGIN
			/*update*/
			UPDATE [Person].[PhoneNumberType] SET
				[Name] = [inserted].[Name],
				[ModifiedDate] = GETDATE()
			FROM [inserted], [deleted]
			WHERE [Person].[PhoneNumberType].[PhoneNumberTypeID] = [deleted].[PhoneNumberTypeID]

			UPDATE [Person].[PersonPhone] SET
				[BusinessEntityID] = [inserted].[BusinessEntityID],
				[PhoneNumber] = [inserted].[PhoneNumber],
				[ModifiedDate] = GETDATE()
			FROM [inserted], [deleted]
			WHERE [Person].[PersonPhone].[BusinessEntityID] = [deleted].[BusinessEntityID]
			AND [Person].[PersonPhone].[PhoneNumber] = [deleted].[PhoneNumber]
		END
	END
	ELSE
	BEGIN
		DELETE FROM [Person].[PersonPhone]
		WHERE [BusinessEntityID] IN (SELECT [BusinessEntityID] FROM [deleted])
		AND [PhoneNumber] IN (SELECT [PhoneNumber] FROM [deleted])

		DELETE FROM [Person].[PhoneNumberType]
		WHERE [PhoneNumberTypeID] IN (SELECT [PhoneNumberTypeID] FROM [deleted])
	END
END;
GO

/*c) Вставьте новую строку в представление, указав новые данные для PhoneNumberType и 
PersonPhone для существующего BusinessEntityID (например 1). Триггер должен добавить новые строки в таблицы 
Person.PhoneNumberType и Person.PersonPhone. Обновите вставленные строки через представление. Удалите строки.*/
INSERT INTO [Person].[PhoneNumberTypeAndPhoneView] (
	[BusinessEntityID],
	[PhoneNumber],
	[Name])
VALUES(1, '111-111-111', 'NewType');

SELECT * FROM [Person].[PersonPhone]
SELECT * FROM [Person].[PhoneNumberType]

UPDATE [Person].[PhoneNumberTypeAndPhoneView] SET 
	[Name] = 'NewType2',
	[PhoneNumber] = '000-000-000'
WHERE [PhoneNumber] = '111-111-111';

DELETE FROM [Person].[PhoneNumberTypeAndPhoneView]
WHERE [PhoneNumber] = '000-000-000';
select * from person.PhoneNumberTypeAndPhoneView