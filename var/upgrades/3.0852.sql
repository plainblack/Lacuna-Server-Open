alter table body add column max_berth tinyint default 1;
alter table empire add column most_recent_message varchar(30) not null default '';
alter table empire add column has_new_messages tinyint(4) not null default 0;

