CREATE TABLE `laws` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `station_id` int(11) NOT NULL,
  `description` text,
  `type` varchar(30) NOT NULL,
  `scratch` mediumblob,
  `date_enacted` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `laws_idx_station_id` (`station_id`),
  KEY `idx_date_enacted` (`date_enacted`),
  CONSTRAINT `laws_fk_station_id` FOREIGN KEY (`station_id`) REFERENCES `body` (`id`)
); 
