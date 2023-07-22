USE [NewDatabase]
GO

/****** Object:  Table [dbo].['Текущий рейтинг студентов$']    Script Date: 10.05.2023 16:55:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[''](
	[Позиция в рейтинге] [float] NULL,
	[ФИО] [nvarchar](255) NULL,
	[СПО] [nvarchar](255) NULL,
	[БиБД] [nvarchar](255) NULL,
	[ММИПиУ] [nvarchar](255) NULL,
	[ФизК] [nvarchar](255) NULL,
	[АПОЭВМиС] [nvarchar](255) NULL,
	[АиПРП] [nvarchar](255) NULL,
	[ВМиКА] [nvarchar](255) NULL
) ON [PRIMARY]
GO

drop table if exists ocenki;
go
CREATE TABLE [dbo].[ocenki](
nam nvarchar(255),
sub nvarchar(255),
ocenka int,
) 
GO

insert into ocenki (nam,sub,ocenka)
(select fio,'Spo', value  from dbo.ocn cross apply string_split(spo,' '))
(select fio,'bibd', value  from dbo.ocn cross apply string_split(bibd,' '))
(select fio,'mpipiy', value  from dbo.ocn cross apply string_split(mpipiy,' '))
(select fio,'fizk', value  from dbo.ocn cross apply string_split(fizk,' '))
(select fio,'apoevmis', value  from dbo.ocn cross apply string_split(apoevmis,' '))
(select fio,'aiprp', value  from dbo.ocn cross apply string_split(aiprp,' '))
(select fio,'vmika', value  from dbo.ocn cross apply string_split(vmika,' '))


select * from ocenki