alter table body change happiness happiness bigint not null default 0;
update ships set speed = 2500, hold_size = 100000 where speed = 100000 and hold_size = 85000 and stealth = 1000 and type = 'cargo_ship';
