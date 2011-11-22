alter table battle_log add column attacked_body_id int not null;
alter table battle_log add column attacked_body_name varchar(30) not null;
alter table battle_log add column attacked_empire_id int default null;
alter table battle_log add column attacked_empire_name varchar(30) default null;
alter table battle_log modify defending_empire_name char(30);

create table ai_scratch_pad (
    id              int(11) not null auto_increment,
    ai_empire_id    int(11) not null,
    body_id         int(11) not null,
    pad             mediumblob,
    primary key (id),
    key aic_idx_ai_empire_id (ai_empire_id),
    key aic_idx_body_id (body_id),
    constraint aic_fk_empire_id foreign key (ai_empire_id) references empire (id)
);

