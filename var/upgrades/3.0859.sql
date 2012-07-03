
CREATE TABLE glyph (
  id INT(11) NOT NULL AUTO_INCREMENT,
  body_id INT(11) NOT NULL,
  type VARCHAR(20) NOT NULL,
  quantity INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY glyph_idx_body_id (body_id),
  CONSTRAINT glyph_fc_body_id FOREIGN KEY (body_id) REFERENCES body (id)
);
 
INSERT INTO glyph (body_id, TYPE, quantity) SELECT body_id,TYPE,COUNT(id) FROM glyphs GROUP BY body_id,TYPE;
CREATE TABLE plan (
  id INT(11) NOT NULL AUTO_INCREMENT,
  body_id INT(11) NOT NULL,
  class VARCHAR(255) NOT NULL,
  level tinyint not NULL,
  extra_build_level tinyint not NULL,
  quantity INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY plan_idx_body_id (body_id),
  CONSTRAINT plan_fc_body_id FOREIGN KEY (body_id) REFERENCES body (id)
);

INSERT INTO plan (body_id,class,level,extra_build_level,quantity) SELECT body_id,class,level,extra_build_level,count(id) from plans group by body_id,class,level,extra_build_level;
                  
