alter table ships add column berth_level tinyint default 1;
delete from probes where empire_id < 0;
