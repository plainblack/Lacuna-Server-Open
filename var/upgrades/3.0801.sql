alter table message add index idx_trash_only (has_trashed,to_id,date_sent);

