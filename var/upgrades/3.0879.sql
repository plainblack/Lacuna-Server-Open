alter table empire add column essentia_free float(11,1) not null default 0 after essentia;
alter table empire add column essentia_game float(11,1) not null default 0 after essentia;
alter table empire add column essentia_paid float(11,1) not null default 0 after essentia;

update empire set essentia_game=essentia;

alter table login_log add column is_sitter int(1) not null default 0;

create table empire_name_change_log (
    id              int(11) not null auto_increment,
    date_stamp      datetime not null,
    empire_id       int(11) not null,
    empire_name     varchar(30) not null,
    old_empire_name varchar(30) not null,
    primary key (id),
    key erl_idx_empire_id (empire_id),
    key erl_idx_date_stamp (date_stamp)
);
