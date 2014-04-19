alter table star add column alliance_id int(11);
alter table star add column seize_strength int(11);
alter table star add column recalc int(11) default 1;

alter table star add foreign key (alliance_id) references alliance(id);

create table seize_star (
    id              int(11) not null auto_increment,
    station_id      int(11) not null,
    star_id         int(11) not null,
    alliance_id     int(11) not null,
    seize_strength  int(11) not null default 0,
    primary key (id),
    key ssf_idx_body_id (station_id),
    key ssf_idx_star_id (star_id),
    key ssf_idx_alliance_id (alliance_id),
    constraint ss_f_body_id foreign key (station_id) references body(id),
    constraint ss_f_star_id foreign key (star_id) references star(id),
    constraint ss_f_alliance_id foreign key (alliance_id) references alliance(id)
);

                
