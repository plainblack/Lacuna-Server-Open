create table config (
    id              int(11) not null auto_increment,
    name            varchar(30) not null,
    value           varchar(256),
    primary key (id),
    key c_idx_key (name)
);
