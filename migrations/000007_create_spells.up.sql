CREATE TABLE spell_templates (
    id             VARCHAR(64) PRIMARY KEY,
    class          VARCHAR(32),
    subclass       VARCHAR(32),
    name           VARCHAR(64) NOT NULL,
    description    TEXT,
    min_level      INT NOT NULL,
    pa_cost        INT NOT NULL,
    range_min      INT NOT NULL,
    range_max      INT NOT NULL,
    area           VARCHAR(16),
    effects        JSONB NOT NULL,
    game_version   VARCHAR(16)
);

CREATE INDEX idx_spell_class ON spell_templates(class);

CREATE TABLE character_spells (
    character_id   UUID NOT NULL,
    spell_id       VARCHAR(64) NOT NULL,
    level_learned  INT NOT NULL,
    spell_level    INT,
    xp             INT,
    unlock_rule    JSONB,
    PRIMARY KEY(character_id, spell_id),
    FOREIGN KEY(spell_id) REFERENCES spell_templates(id)
);

CREATE INDEX idx_character_spell ON character_spells(character_id, spell_id); 