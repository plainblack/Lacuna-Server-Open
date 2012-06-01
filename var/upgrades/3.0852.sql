alter table body add column max_berth tinyint default 1;
alter table empire add column has_new_messages integer(11) not null default 0;
alter table empire add column skip_incoming_ships tinyint(4) not null default 0;
alter table empire add column latest_message_id integer(11);

