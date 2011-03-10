alter table body add column alliance_id int;
alter table body add foreign key body_fk_alliance_id (alliance_id) references alliance (id) on delete set null;
