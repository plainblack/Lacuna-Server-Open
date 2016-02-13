
create table fleet (
    id              int(11) not null auto_increment,
    body_id         int(11) not null,
    shipyard_id     int(11) not null,
    date_started    datetime not null,
    date_available  datetime not null,
    mark            varchar(10) not null,
    type            varchar(30) not null,
    task            varchar(30) not null,
    name            varchar(30) not null,
    speed           int(11) not null,
    stealth         int(11) not null,
    combat          int(11) not null,
    hold_size       int(11) not null,
    payload         mediumblob,
    roundtrip       tinyint(4) not null default 0,
    direction       varchar(3) not null,
    foreign_body_id int(11),
    foreign_star_id int(11),
    berth_level     tinyint(4) default 1,
    quantity        float(11,1) not null default 1,
    primary key (id),
    key f_mark (mark),
    key f_idx_body_id (body_id),
    key f_idx_foreign_body_id (foreign_body_id),
    key f_idx_foreign_star_id (foreign_star_id),
    constraint wc_f_body_id foreign key (body_id) references body (id),
    constraint wc_f_foreign_body_id foreign key (foreign_body_id) references body (id),
    constraint wc_f_foreign_star_id foreign key (foreign_star_id) references star (id)
);

alter table market add column `fleet_id` int(11) NOT NULL default 0;
