alter table star add column needs_recalc tinyint not null default 0;
alter table star add column influence int not null default 0;
alter table star add index idx_recalc (needs_recalc);

delete from laws where type = 'Jurisdiction';

CREATE TABLE stationinfluence (
  id integer(11) NOT NULL auto_increment,
  station_id integer NOT NULL,
  star_id integer NOT NULL,
  alliance_id integer NOT NULL,
  oldinfluence integer NOT NULL,
  oldstart datetime NULL,
  influence integer NOT NULL,
  started_influence datetime NOT NULL,
  INDEX stationinfluence_idx_alliance_id (alliance_id),
  INDEX stationinfluence_idx_star_id (star_id),
  INDEX stationinfluence_idx_station_id (station_id),
  PRIMARY KEY (id),
  CONSTRAINT stationinfluence_fk_alliance_id FOREIGN KEY (alliance_id) REFERENCES alliance (id),
  CONSTRAINT stationinfluence_fk_star_id FOREIGN KEY (star_id) REFERENCES star (id),
  CONSTRAINT stationinfluence_fk_station_id FOREIGN KEY (station_id) REFERENCES body (id) ON DELETE CASCADE
);

DELIMITER //

CREATE TRIGGER stationinfluence_cleanup after delete ON stationinfluence
  FOR EACH ROW BEGIN
    UPDATE star s SET s.needs_recalc = 1 WHERE s.id = OLD.star_id;
END //

DELIMITER ;

-- after this is done, run bin/initial_jurisdiction.pl
