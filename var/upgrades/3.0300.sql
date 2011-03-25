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

