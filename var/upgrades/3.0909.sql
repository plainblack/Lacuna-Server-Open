alter table ships add column number_of_docks int default 1;
alter table ships modify hold_size bigint;
alter table battle_log add column attacking_number int default 1;
alter table battle_log add column defending_number int default 1;

CREATE TABLE empire_admin_notes (
  id integer(11) NOT NULL auto_increment,
  date_stamp datetime NOT NULL,
  empire_id integer(11) NOT NULL,
  empire_name varchar(30) NOT NULL,
  notes text NOT NULL,
  creator varchar(30) NOT NULL,
  INDEX idx_empire_id (empire_id),
  INDEX idx_empire_name (empire_name),
  PRIMARY KEY (id)
);
