CREATE TABLE `mission` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mission_file_name` varchar(100) NOT NULL,
  `zone` varchar(16) NOT NULL,
  `date_posted` datetime NOT NULL,
  `max_university_level` tinyint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_zone_date_posted` (`zone`,`date_posted`)
);