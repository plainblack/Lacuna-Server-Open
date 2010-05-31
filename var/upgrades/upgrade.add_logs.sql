alter table spies add column `date_created` datetime NOT NULL;
alter table spies add column `mission_count` int(11) NOT NULL DEFAULT '0';
alter table spies add column `mission_successes` int(11) NOT NULL DEFAULT '0';
alter table spies add column `times_captured` int(11) NOT NULL DEFAULT '0';
alter table spies add column `times_turned` int(11) NOT NULL DEFAULT '0';
alter table spies add column `seeds_planted` int(11) NOT NULL DEFAULT '0';
alter table spies add column `spies_killed` int(11) NOT NULL DEFAULT '0';
alter table spies add column `spies_captured` int(11) NOT NULL DEFAULT '0';
alter table spies add column `spies_turned` int(11) NOT NULL DEFAULT '0';
alter table spies add column `things_destroyed` int(11) NOT NULL DEFAULT '0';
alter table spies add column `things_stolen` int(11) NOT NULL DEFAULT '0';


CREATE TABLE `colony_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_stamp` datetime NOT NULL,
  `empire_id` int(11) NOT NULL,
  `empire_name` char(30) NOT NULL,
  `planet_id` int(11) NOT NULL,
  `planet_name` char(30) NOT NULL,
  `population` int(11) NOT NULL,
  `building_count` int(3) NOT NULL,
  `average_building_level` float(3,2) NOT NULL,
  `highest_building_level` int(3) NOT NULL,
  `lowest_building_level` int(3) NOT NULL,
  `food_hour` int(11) NOT NULL,
  `energy_hour` int(11) NOT NULL,
  `waste_hour` int(11) NOT NULL,
  `ore_hour` int(11) NOT NULL,
  `water_hour` int(11) NOT NULL,
  PRIMARY KEY (`id`)
);
CREATE TABLE `empire_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_stamp` datetime NOT NULL,
  `empire_id` int(11) NOT NULL,
  `empire_name` char(30) NOT NULL,
  `colony_count` int(3) NOT NULL,
  `population` int(11) NOT NULL,
  `building_count` int(3) NOT NULL,
  `university_level` int(3) NOT NULL,
  `average_building_level` float(3,2) NOT NULL,
  `highest_building_level` int(3) NOT NULL,
  `lowest_building_level` int(3) NOT NULL,
  `food_hour` int(11) NOT NULL,
  `energy_hour` int(11) NOT NULL,
  `waste_hour` int(11) NOT NULL,
  `ore_hour` int(11) NOT NULL,
  `water_hour` int(11) NOT NULL,
  `spy_count` int(11) NOT NULL,
  `avg_spy_success_rate` int(11) NOT NULL,
  PRIMARY KEY (`id`)
);
CREATE TABLE `espionage_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_stamp` datetime NOT NULL,
  `empire_id` int(11) NOT NULL,
  `empire_name` char(30) NOT NULL,
  `amount` int(11) NOT NULL,
  `description` char(90) NOT NULL,
  PRIMARY KEY (`id`)
);
CREATE TABLE `essentia_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_stamp` datetime NOT NULL,
  `empire_id` int(11) NOT NULL,
  `empire_name` char(30) NOT NULL,
  `api_key` char(40) DEFAULT NULL,
  `amount` int(11) NOT NULL,
  `description` char(90) NOT NULL,
  PRIMARY KEY (`id`)
);
CREATE TABLE `login_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_stamp` datetime NOT NULL,
  `empire_id` int(11) NOT NULL,
  `empire_name` char(30) NOT NULL,
  `api_key` char(40) DEFAULT NULL,
  `session_id` char(40) NOT NULL,
  `log_out_date` datetime DEFAULT NULL,
  `extended` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
);
CREATE TABLE `spy_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_stamp` datetime NOT NULL,
  `empire_id` int(11) NOT NULL,
  `empire_name` char(30) NOT NULL,
  `spy_name` char(30) NOT NULL,
  `spy_id` int(11) NOT NULL,
  `level` int(11) NOT NULL,
  `level_delta` int(11) NOT NULL DEFAULT '0',
  `success_rate` float(11,2) NOT NULL,
  `success_rate_delta` float(11,2) NOT NULL DEFAULT '0.00',
  `age` int(11) NOT NULL,
  `times_captured` int(11) NOT NULL DEFAULT '0',
  `times_turned` int(11) NOT NULL DEFAULT '0',
  `seeds_planted` int(11) NOT NULL DEFAULT '0',
  `spies_killed` int(11) NOT NULL DEFAULT '0',
  `spies_captured` int(11) NOT NULL DEFAULT '0',
  `spies_turned` int(11) NOT NULL DEFAULT '0',
  `things_destroyed` int(11) NOT NULL DEFAULT '0',
  `things_stolen` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `spy_log_idx_spy_id` (`spy_id`),
  CONSTRAINT `spy_log_fk_spy_id` FOREIGN KEY (`spy_id`) REFERENCES `spies` (`id`)
);
