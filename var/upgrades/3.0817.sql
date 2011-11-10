alter table alliance_log add column population_rank int(11) not null default '0';
alter table alliance_log add column space_station_count_rank int(11) not null default '0';
alter table alliance_log add column influence_rank int(11) not null default '0';
alter table alliance_log add index idx_population_rank (population_rank);
alter table alliance_log add index idx_space_station_count_rank (space_station_count_rank);
alter table alliance_log add index idx_influence_rank (influence_rank);
alter table empire add column building_boost datetime NOT NULL default '2011-01-01 01:00:00';
