alter table body add column notes text;
alter table propositions drop column votes_yes, drop column votes_no, drop column votes_needed;
