alter table empire add column `species_name` varchar(30) NOT NULL default 'Human';
alter table empire add column  `species_description` text;
alter table empire add column  `min_orbit` tinyint(4) NOT NULL DEFAULT '3';
alter table empire add column  `max_orbit` tinyint(4) NOT NULL DEFAULT '3';
alter table empire add column  `manufacturing_affinity` tinyint(4) NOT NULL DEFAULT '4';
alter table empire add column  `deception_affinity` tinyint(4) NOT NULL DEFAULT '4';
alter table empire add column  `research_affinity` tinyint(4) NOT NULL DEFAULT '4';
alter table empire add column  `management_affinity` tinyint(4) NOT NULL DEFAULT '4';
alter table empire add column  `farming_affinity` tinyint(4) NOT NULL DEFAULT '4';
alter table empire add column  `mining_affinity` tinyint(4) NOT NULL DEFAULT '4';
alter table empire add column  `science_affinity` tinyint(4) NOT NULL DEFAULT '4';
alter table empire add column  `environmental_affinity` tinyint(4) NOT NULL DEFAULT '4';
alter table empire add column  `political_affinity` tinyint(4) NOT NULL DEFAULT '4';
alter table empire add column  `trade_affinity` tinyint(4) NOT NULL DEFAULT '4';
alter table empire add column  `growth_affinity` tinyint(4) NOT NULL DEFAULT '4';
update empire, species set
    empire.species_name = species.name,
    empire.species_description = species.description,
    empire.min_orbit = species.min_orbit,
    empire.max_orbit = species.max_orbit,
    empire.manufacturing_affinity = species.manufacturing_affinity,
    empire.deception_affinity = species.deception_affinity,
    empire.research_affinity = species.research_affinity,
    empire.management_affinity = species.management_affinity,
    empire.farming_affinity = species.farming_affinity,
    empire.mining_affinity = species.mining_affinity,
    empire.science_affinity = species.science_affinity,
    empire.environmental_affinity = species.environmental_affinity,
    empire.political_affinity = species.political_affinity,
    empire.trade_affinity = species.trade_affinity,
    empire.growth_affinity = species.growth_affinity
    where empire.species_id=species.id;
alter table species drop key idx_empire_id;
alter table empire drop foreign key empire_fk_species_id;
alter table empire drop key empire_idx_species_id;
alter table empire drop column species_id;
drop table species;
