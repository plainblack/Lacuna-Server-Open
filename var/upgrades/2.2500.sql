alter table invite add column `zone` varchar(16);
update invite,empire,body set invite.zone=body.zone where invite.inviter_id=empire.id and empire.home_planet_id=body.id;
