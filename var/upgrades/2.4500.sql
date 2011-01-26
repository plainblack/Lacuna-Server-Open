drop table saben_target;
alter table empire change essentia essentia float(11,1) not null default 0;
alter table essentia_code change amount amount float(11,1) not null default 0;
alter table market change ask ask float(11,1) not null default 1;
alter table essentia_log change amount amount float(11,1) not null default 0;
