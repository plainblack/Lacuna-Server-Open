alter table empire_log add column empire_size_rank int(11) not null;
alter table empire_log add column university_level_rank int(11) not null;
alter table empire_log add column offense_success_rate_rank int(11) not null;
alter table empire_log add column defense_success_rate_rank int(11) not null;
alter table empire_log add column dirtiest_rank int(11) not null;
alter table empire_log add column happiness_hour int(11) not null;
alter table empire_log add index idx_empire_size_rank (empire_size_rank);
alter table colony_log add column happiness_hour int(11) not null;
alter table colony_log add column population_rank int(11) not null;
alter table spies_log add column level_rank int(11) not null;
alter table spies_log add column success_rate_rank int(11) not null;
alter table spies_log add column dirtiest_rank int(11) not null;

