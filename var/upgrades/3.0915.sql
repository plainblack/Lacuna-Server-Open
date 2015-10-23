CREATE TABLE promotion (
  id integer(11) NOT NULL auto_increment,
  start_date datetime NOT NULL,
  end_date datetime NOT NULL,
  type varchar(30) NOT NULL,
  min_purchase integer NULL,
  max_purchase integer NULL,
  payload mediumblob NULL,
  PRIMARY KEY (id)
);

alter table empire drop column has_new_messages;
alter table login_log add column browser_fingerprint varchar(32) NULL;
alter table login_log add index idx_fingerprint (browser_fingerprint);
