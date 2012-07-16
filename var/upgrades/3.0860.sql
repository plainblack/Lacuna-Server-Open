create table empire_rpc_log (
    id              int(11) not null auto_increment,
    date_stamp      datetime not null,
    empire_id       int(11) not null,
    empire_name     varchar(30) not null,
    rpc             int(11) not null default 0,
    limits          int(11) not null default 0,
    primary key (id),
    key erl_idx_empire_id (empire_id),
    key erl_idx_date_stamp (date_stamp)
);
