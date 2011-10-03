alter table colony_log add column is_space_station int(11) not null default '0';
alter table colony_log add column influence int(11) not null default '0';



alter table empire_log add column space_station_count int(11) not null default '0';
alter table empire_log add column influence int(11) not null default '0';

alter table body add column surface_version int(11) not null default '0';

