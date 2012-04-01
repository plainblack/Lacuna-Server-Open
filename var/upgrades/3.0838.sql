CREATE TABLE `excavators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `planet_id` int(11) NOT NULL,
  `body_id` int(11) NOT NULL,
  `empire_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
);
alter table empire   add column `skip_excavator_artifact` tinyint NOT NULL default 0;
alter table empire   add column `skip_excavator_destroyed` tinyint NOT NULL default 0;
alter table building add column `last_check` datetime NOT NULL default '2012-03-23 23:00:00';
