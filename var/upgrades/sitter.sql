-- Table: sitter_auths
--
CREATE TABLE sitter_auths (
  baby_id integer NOT NULL,
  sitter_id integer NOT NULL,
  expiry datetime NOT NULL,
  INDEX sitter_auths_idx_baby_id (baby_id),
  INDEX sitter_auths_idx_sitter_id (sitter_id),
  PRIMARY KEY (baby_id, sitter_id),
  CONSTRAINT sitter_auths_fk_baby_id FOREIGN KEY (baby_id) REFERENCES empire (id) ON DELETE CASCADE,
  CONSTRAINT sitter_auths_fk_sitter_id FOREIGN KEY (sitter_id) REFERENCES empire (id) ON DELETE CASCADE
) ENGINE=InnoDB--
