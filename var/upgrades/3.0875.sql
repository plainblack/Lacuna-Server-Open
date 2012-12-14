
create table schedule (
    id              int(11) not null auto_increment,
    queue           varchar(30) not null,
    job_id          int(11) not null default 0,
    delivery        datetime not null,
    priority        int(11) not null default 0,
    parent_table    varchar(30) not null,
    parent_id       int(11) not null,
    task            varchar(30) not null, 
    args            mediumblob,
    primary key (id)
);

