CREATE TABLE `propositions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `station_id` int(11) NOT NULL,
  `votes_needed` int(11) NOT NULL DEFAULT '1',
  `votes_yes` int(11) NOT NULL DEFAULT '0',
  `votes_no` int(11) NOT NULL DEFAULT '0',
  `description` text,
  `type` varchar(30) NOT NULL,
  `scratch` mediumblob,
  `date_ends` datetime NOT NULL,
  `proposed_by_id` int(11) NOT NULL,
  `status` varchar(10) NOT NULL DEFAULT 'Pending',
  PRIMARY KEY (`id`),
  KEY `propositions_idx_proposed_by_id` (`proposed_by_id`),
  KEY `propositions_idx_station_id` (`station_id`),
  KEY `idx_status_date_ends` (`status`,`date_ends`),
  CONSTRAINT `propositions_fk_proposed_by_id` FOREIGN KEY (`proposed_by_id`) REFERENCES `empire` (`id`),
  CONSTRAINT `propositions_fk_station_id` FOREIGN KEY (`station_id`) REFERENCES `body` (`id`)
);
CREATE TABLE `votes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `proposition_id` int(11) NOT NULL,
  `empire_id` int(11) NOT NULL,
  `vote` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `votes_idx_empire_id` (`empire_id`),
  KEY `votes_idx_proposition_id` (`proposition_id`),
  CONSTRAINT `votes_fk_empire_id` FOREIGN KEY (`empire_id`) REFERENCES `empire` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `votes_fk_proposition_id` FOREIGN KEY (`proposition_id`) REFERENCES `propositions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
);