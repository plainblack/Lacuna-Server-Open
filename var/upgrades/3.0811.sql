CREATE TABLE `battle_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_stamp` datetime NOT NULL,
  `attacking_empire_id` int(11) NOT NULL,
  `attacking_empire_name` char(30) NOT NULL,
  `attacking_body_id` int(11) NOT NULL,
  `attacking_body_name` char(30) NOT NULL,
  `attacking_unit_name` char(60) NOT NULL,
  `defending_empire_id` int(11) NOT NULL,
  `defending_empire_name` char(30) NOT NULL,
  `defending_body_id` int(11) NOT NULL,
  `defending_body_name` char(30) NOT NULL,
  `defending_unit_name` char(60) NOT NULL,
  `victory_to` char(8) NOT NULL,
  PRIMARY KEY (`id`)
);

alter table empire add column `skip_attack_messages` tinyint NOT NULL default 0;

