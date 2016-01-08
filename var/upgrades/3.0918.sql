# tidy up of some unused tables

drop table glyphs;
drop table body_old;
drop table propositions_bak;
drop table temp;
drop table trades;
drop table votes_bak;
delete from cargo_log;
delete from login_log where date_stamp < "2015-01-01 00:00:00";
delete from lottery_log where date_stamp < "2015-01-01 00:00:00";
delete from news where date_posted < "2015-01-01 00:00:00";

