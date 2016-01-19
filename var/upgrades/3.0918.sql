# tidy up of some unused tables

drop table glyphs;
drop table body_old;
drop table propositions_bak;
drop table temp;
drop table trades;
drop table votes_bak;
delete from cargo_log;
create table lottery_log_bu select * from lottery_log;
delete from lottery_log where date_stamp < "2015-01-01 00:00:00";
create table login_log_bu select * from login_log;
delete from login_log where date_stamp < "2015-01-01 00:00:00";
create table news_bu select * from news;
delete from news where date_posted < "2015-01-01 00:00:00";
