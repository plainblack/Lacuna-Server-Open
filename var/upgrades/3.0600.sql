alter table message add column has_trashed tinyint not null default 0;

alter table empire add column `skip_found_nothing` tinyint NOT NULL default 0;
alter table empire add column `skip_excavator_resources` tinyint NOT NULL default 0;
alter table empire add column `skip_excavator_glyph` tinyint NOT NULL default 0;
alter table empire add column `skip_excavator_plan` tinyint NOT NULL default 0;
alter table empire add column `skip_spy_recovery` tinyint NOT NULL default 0;
alter table empire add column `skip_probe_detected` tinyint NOT NULL default 0;

