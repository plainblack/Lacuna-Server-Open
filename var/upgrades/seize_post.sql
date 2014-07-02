# Script to be run *after* the seize script runs and the code has been updated.

drop table if exists votes;
drop table if exists laws;
drop table if exists propositions;
drop table if exists votes_bak;
drop table if exists propositions_bak;
drop table if exists spies_bak;
drop table if exists temp;
drop table if exists glyphs;
drop table if exists cargo_log;
drop table if exists trades;

