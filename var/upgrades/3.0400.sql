CREATE TABLE `laws` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `station_id` int(11) NOT NULL,
  `description` text,
  `type` varchar(30) NOT NULL,
  `scratch` mediumblob,
  `date_enacted` datetime NOT NULL,
  `star_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `laws_idx_star_id` (`star_id`),
  KEY `laws_idx_station_id` (`station_id`),
  KEY `idx_date_enacted` (`date_enacted`),
  CONSTRAINT `laws_fk_star_id` FOREIGN KEY (`star_id`) REFERENCES `star` (`id`) ON DELETE SET NULL,
  CONSTRAINT `laws_fk_station_id` FOREIGN KEY (`station_id`) REFERENCES `body` (`id`)
);
alter table star add column station_id int;
alter table star add foreign key star_fk_alliance_id (station_id) references body (id) on delete set null;
alter table market drop column has_spy;
CREATE TABLE `mercenary_market` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_offered` datetime NOT NULL,
  `body_id` int(11) NOT NULL,
  `ship_id` int(11) NOT NULL,
  `ask` float(11,1) NOT NULL,
  `cost` float(11,1) NOT NULL,
  `payload` mediumblob NOT NULL,
  PRIMARY KEY (`id`)
);
