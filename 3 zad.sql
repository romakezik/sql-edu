USE AdventureWorks2012;
GO

drop table if exists #ep
go
drop table if exists epcop
go
drop table if exists ep
create table ep
(
    id       uniqueidentifier primary key default NEWID(),
    name     nvarchar(20),
    modified nvarchar(300)                default ''
);
go

create table epcop
(
    id       uniqueidentifier primary key default NEWID(),
    name     nvarchar(20),
    modified nvarchar(300)                default ''
)
go

drop view if exists epview
go

create view epview as
select *
from ep;
go

create table #ep
(
    id       uniqueidentifier primary key DEFAULT NEWID(),
    name     nvarchar(20),
    modified nvarchar(300)                default ''
);
go

create trigger on_insert
    on epview
    after insert
    as
begin
    insert into #ep(name, modified)
    select inserted.name, 'Inserted on ' + CONVERT(nvarchar, getdate())
    from inserted;
end
go

create trigger on_update
    on epview
    after update
    as
begin
    insert into #ep(name, modified)
    select inserted.name, 'Updated on ' + CONVERT(nvarchar, getdate())
    from inserted;
end
go

create trigger on_delete
    on epview
    after delete
    as
begin
    insert into #ep(modified)
    select 'Deleted on ' + CONVERT(nvarchar, getdate())
    from deleted;
end
go

insert into epview(name)
values ('hello')
go

insert into epcop(name)
values ('hello1234567'),
       ('goodbye')
go

update epview
set name = 'hello1'
where name = 'hello'
go

delete
from epview
where [name] = 'hello1'
go

select *
from #ep

select *
from epview

MERGE epcop AS Target
USING ep AS Source
ON Source.id = Target.id
WHEN NOT MATCHED BY Target THEN
    INSERT (name)
    VALUES (Source.name);

	drop table if exists epdep

create table epdep
(
    id uniqueidentifier primary key default NEWID(),
    depName nvarchar(100),
    animalId uniqueidentifier references ep(id) on delete cascade
)

insert into epdep(depName, animalId)
values
    ('LionCage', '26E87C03-CEB2-4D0A-95EA-1007DE9D8366'),
    ('SomeCage', 'D44EBC5A-166F-4D66-BC38-B4E324C4657B')

SELECT * FROM ep