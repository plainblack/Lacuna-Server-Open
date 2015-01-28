alter table ships add column number_of_docks int default 1;
alter table ships modify hold_size bigint;
alter table battle_log add column attacking_number int default 1;
alter table battle_log add column defending_number int default 1;
