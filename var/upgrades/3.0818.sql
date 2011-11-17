alter table battle_log add column attacked_body_id int not null;
alter table battle_log add column attacked_body_name varchar(30) not null;
alter table battle_log add column attacked_empire_id int default null;
alter table battle_log add column attacked_empire_name varchar(30) default null;
alter table battle_log modify defending_empire_name char(30);
