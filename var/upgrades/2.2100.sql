alter table empire add column `skip_medal_messages` tinyint NOT NULL default 0;
alter table empire add column `skip_pollution_warnings` tinyint NOT NULL default 0;
alter table empire add column `skip_resource_warnings` tinyint NOT NULL default 0;
alter table empire add column `skip_happiness_warnings` tinyint NOT NULL default 0;
update ships set type='snark' where type='bomber';