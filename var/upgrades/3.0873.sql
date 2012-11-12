alter table body  add column `unhappy_date` datetime NOT NULL default '2012-11-10 04:00:00';
alter table body  add column `unhappy` tinyint(4) NOT NULL default 0;
alter table spies add column `next_task` varchar(30) NOT NULL default 'Idle';
