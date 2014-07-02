# NOTE # It is highly recommended that a full backup of the database is
# made before running this script.
# 
# AFTER this script has been run, and the code has been updated then
# you can run the 'post.sql' script to tidy up the database
#
alter table star add column alliance_id int(11);
alter table star add column influence int(11);
alter table star add column recalc int(11) default 1;

alter table star add foreign key (alliance_id) references alliance(id);

alter table body add column station_recalc int(11);

drop table if exists influence;
create table influence (
    id              int(11) not null auto_increment,
    station_id      int(11) not null,
    star_id         int(11) not null,
    alliance_id     int(11) not null,
    influence       int(11) not null default 0,
    primary key (id),
    key ssf_idx_body_id (station_id),
    key ssf_idx_star_id (star_id),
    key ssf_idx_alliance_id (alliance_id),
    constraint ss_f_body_id foreign key (station_id) references body(id),
    constraint ss_f_star_id foreign key (star_id) references star(id),
    constraint ss_f_alliance_id foreign key (alliance_id) references alliance(id)
);

drop table if exists law;
create table law (
    id              int(11) not null auto_increment,
    name            varchar(30) not null,
    description     text,
    type            varchar(30) not null,
    date_enacted    datetime not null,
    alliance_id     int(11) not null,
    star_id         int(11),
    zone            varchar(16),
    scratch         mediumblob,
    primary key (id),
    key law_idx_date_enacted (date_enacted),
    key law_idx_alliance_id (alliance_id),
    key law_idx_star_id (star_id),
    key law_idx_zone (zone),
    constraint law_f_alliance_id foreign key (alliance_id) references alliance(id),
    constraint law_f_star_id foreign key (star_id) references star(id)
);

drop table if exists proposition;
create table proposition (
    id              int(11) not null auto_increment,
    name            varchar(30) not null,
    alliance_id     int(11) not null,
    station_id      int(11),
    votes_needed    int(11) not null default 1,
    votes_yes       int(11) not null default 0,
    votes_no        int(11) not null default 0,
    description     text,
    type            varchar(30) not null,
    scratch         mediumblob,
    date_ends       datetime not null,
    proposed_by_id  int(11) not null,
    status          varchar(10) not null default 'Pending',
    zone            varchar(16),
    primary key (id),
    key prop_idx_alliance_id (alliance_id),
    key prop_idx_station_id (station_id),
    key prop_idx_proposed_by_id (proposed_by_id),
    key prop_idx_status (status),
    constraint prop_f_alliance_id foreign key (alliance_id) references alliance(id),
    constraint prop_f_station_id foreign key (station_id) references body(id),
    constraint prop_f_proposed_by_id foreign key (proposed_by_id) references empire(id)
);

drop table if exists vote;
create table vote (
    id              int(11) not null auto_increment,
    proposition_id  int(11) not null,
    empire_id       int(11) not null,
    vote            int(11) not null default 0,
    primary key (id),
    key vote_idx_proposition_id (proposition_id),
    key vote_idx_empire_id (empire_id),
    constraint vote_f_proposition_id foreign key (proposition_id) references proposition(id),
    constraint vote_f_empire_id foreign key (empire_id) references empire(id)
);



