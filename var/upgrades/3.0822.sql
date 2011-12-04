CREATE TABLE ai_battle_summary (
    id int(11) NOT NULL AUTO_INCREMENT,
    attacking_empire_id int(11) NOT NULL,
    defending_empire_id int(11) NOT NULL,
    attack_victories int(11) NOT NULL,
    defense_victories int(11) NOT NULL,
    PRIMARY KEY (id)
);


