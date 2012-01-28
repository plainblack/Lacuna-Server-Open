alter table market add column speed int(11) not null default 0;
alter table market add column x int(11) not null default 0;
alter table market add column y int(11) not null default 0;
alter table market add column trade_range int(11) not null default 0;

update market set transfer_type='trade' where transfer_type != 'transporter';
update market,body set market.x = body.x, market.y = body.y where market.body_id=body.id;
update market,ships set market.speed = ships.speed where market.ship_id=ships.id;
update market set trade_range=500 where transfer_type='trade';
