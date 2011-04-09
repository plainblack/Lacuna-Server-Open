CREATE TABLE `taxes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `empire_id` int(11) NOT NULL,
  `station_id` int(11) NOT NULL,
  `paid_6` int(11) NOT NULL DEFAULT 0,
  `paid_5` int(11) NOT NULL DEFAULT 0,
  `paid_4` int(11) NOT NULL DEFAULT 0,
  `paid_3` int(11) NOT NULL DEFAULT 0,
  `paid_2` int(11) NOT NULL DEFAULT 0,
  `paid_1` int(11) NOT NULL DEFAULT 0,
  `paid_0` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `taxes_idx_empire_id` (`empire_id`),
  KEY `taxes_idx_station_id` (`station_id`),
  CONSTRAINT `taxes_fk_empire_id` FOREIGN KEY (`empire_id`) REFERENCES `empire` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `taxes_fk_station_id` FOREIGN KEY (`station_id`) REFERENCES `body` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
);


