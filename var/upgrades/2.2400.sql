alter table empire_log add column `alliance_id` int;
alter table empire_log add column `alliance_name` varchar(30);
alter table weekly_medal_winner add column `date_stamp` datetime not null;
 CREATE TABLE `alliance_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_stamp` datetime NOT NULL,
  `alliance_id` int(11) NOT NULL,
  `alliance_name` varchar(30) NOT NULL,
  `member_count` int(11) NOT NULL,
  `space_station_count` int(11) NOT NULL,
  `influence` int(11) NOT NULL,
  `colony_count` int(11) NOT NULL,
  `population` int(11) NOT NULL,
  `average_empire_size` int(11) NOT NULL,
  `average_empire_size_rank` bigint NOT NULL,
  `average_university_level` float(5,2) NOT NULL,
  `building_count` int(11) NOT NULL,
  `average_building_level` float(5,2) NOT NULL,
  `spy_count` int(11) NOT NULL,
  `offense_success_rate` float(6,6) NOT NULL,
  `offense_success_rate_rank` int(11) NOT NULL,
  `defense_success_rate` float(6,6) NOT NULL,
  `defense_success_rate_rank` int(11) NOT NULL,
  `dirtiest` int(11) NOT NULL DEFAULT '0',
  `dirtiest_rank` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_average_empire_size_rank` (`average_empire_size_rank`),
  KEY `idx_offense_success_rate_rank` (`offense_success_rate_rank`),
  KEY `idx_defense_success_rate_rank` (`defense_success_rate_rank`),
  KEY `idx_dirtiest_rank` (`dirtiest_rank`)
);
