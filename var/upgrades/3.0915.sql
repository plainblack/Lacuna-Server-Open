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
