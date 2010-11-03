CREATE TABLE `saben_target` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `target_empire_id` int(11) NOT NULL,
  `saben_colony_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
);
alter table message change recipients recipients mediumblob;
alter table message change attachments attachments mediumblob;
alter table building change `work` `work` mediumblob;
alter table ships change payload payload mediumblob;
alter table trades change payload payload mediumblob;
alter table cargo_log change `data` `data` mediumblob;
