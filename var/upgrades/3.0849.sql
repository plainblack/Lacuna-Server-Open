
create table waste_chain (
    id              int(11) not null auto_increment,
    planet_id       int(11) not null,
    star_id         int(11) not null,
    waste_hour      int(11) not null default 0,
    percent_transferred int(11) not null default 0,
    primary key (id),
    key wc_idx_planet_id (planet_id),
    key wc_idx_star_id (star_id),
    constraint wc_fk_planet_id foreign key (planet_id) references body (id),
    constraint wc_fk_star_id foreign key (star_id) references star (id)
);

