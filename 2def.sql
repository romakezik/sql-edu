
            drop table if exists Zoo
            go
            drop table if exists #Zoo
            go
			drop table if exists ZooCopy
            go
		    drop view if exists ZooView 

            create table Zoo
            (
                id       uniqueidentifier primary key default NEWID(),
                name     nvarchar(20),
                modified nvarchar(300) default ''
            );
            go


            create table ZooCopy
            (
                id       uniqueidentifier primary key default NEWID(),
                name     nvarchar(20),
                modified nvarchar(300) default ''
            );
			go

            create view ZooView as
                select * from Zoo;
				go

             create table #Zoo
            (
                id       uniqueidentifier primary key DEFAULT NEWID(),
                name     nvarchar(20),
                modified nvarchar(300) default ''
            );
             go

            create trigger on_insert
                on Zoo
                after insert
                as
            begin
                insert into #Zoo(name, modified)
                select inserted.name, 'Inserted on ' + CONVERT(nvarchar,getdate())
                from inserted;
            end
            go

            create trigger on_update
                on Zoo
                after update
                as
            begin
                insert into #Zoo(name, modified)
                select inserted.name, 'Updated on ' + CONVERT(nvarchar,getdate())
                from inserted;
            end
            go

            create trigger on_delete
                        on Zoo
                        after delete
                        as
                    begin
                        insert into #Zoo(modified)
                        select 'Deleted on ' + CONVERT(nvarchar,getdate())
                        from deleted;
                    end
            go

    insert into Zoo(name) values (
                                  'a'
                                 )
    go

insert into ZooCopy(name) values ('aao1'),
                              ('bb1')
go

    update Zoo set name = 'a1' where name = 'a'
    go

    delete from Zoo where [name] = 'a1'
    go

select * from #Zoo

MERGE ZooCopy AS Target
USING Zoo AS Source
ON Source.id = Target.id
WHEN NOT MATCHED BY Target THEN
    INSERT (name)
    VALUES (Source.name);

	select * from ZooCopy;