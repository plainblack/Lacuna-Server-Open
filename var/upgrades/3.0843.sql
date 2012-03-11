alter table essentia_code add column `empire_id` int default 0;
alter table essentia_log  add column `from_id`   int default 0;
alter table essentia_log  add column `from_name` varchar(30) default "";
