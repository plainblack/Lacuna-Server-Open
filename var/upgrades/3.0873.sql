alter table body  add column `depression` datetime NOT NULL default '2012-11-10 04:00:00';
alter table body  add column `depressed` tinyint(4) not null default 0,
alter table spies add column next_task varchar(30) NOT NULL defualt 'Idle';
