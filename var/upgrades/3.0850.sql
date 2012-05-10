
create table supply_chain (
    id              int(11) not null auto_increment,
    planet_id       int(11) not null,
    building_id     int(11) not null,
    target_id       int(11) not null,
    resource_hour   int(11) not null default 0,
    resource_type   varchar(32) not null,
    percent_transferred int(11) not null default 0,
    primary key (id),
    key rc_idx_planet_id (planet_id),
    key rc_idx_building_id (building_id),
    key rc_idx_target_id (target_id),
    constraint rc_fk_planet_id foreign key (planet_id) references planet (id),
    constraint rc_fk_building_id foreign key (building_id) references building (id),
    constraint rc_fk_target_id foreign key (target_id) references planet (id)
);

