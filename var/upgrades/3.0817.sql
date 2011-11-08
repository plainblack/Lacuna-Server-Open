alter table alliance_log add column population_rank int(11) not null default '0';
alter table alliance_log add column space_station_count_rank int(11) not null default '0';
alter table alliance_log add column influence_rank int(11) not null default '0';
alter table alliance_log add index idx_population_rank (population_rank);
alter table alliance_log add index idx_space_station_count_rank space_station_count_rank);
alter table alliance_log add index idx_influence_rank (influence_rank);

