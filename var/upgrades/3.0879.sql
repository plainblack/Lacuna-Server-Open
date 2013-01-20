alter table empire add column essentia_free float(11,1) not null default 0 after essentia;
alter table empire add column essentia_game float(11,1) not null default 0 after essentia;
alter table empire add column essentia_paid float(11,1) not null default 0 after essentia;

update empire set essentia_game=essentia;

