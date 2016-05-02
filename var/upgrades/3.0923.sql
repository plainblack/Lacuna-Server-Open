create table survey (
    empire_id   int(11) not null,
    choice      int(11) not null default 0,
    comment     text not null default '',
    primary key (empire_id),
    constraint survey_fk_empire_id foreign key (empire_id) references empire (id)
);

