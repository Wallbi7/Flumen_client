-- Migration pour créer la table characters
CREATE TABLE IF NOT EXISTS characters (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(20) NOT NULL UNIQUE,
    class VARCHAR(20) NOT NULL CHECK (class IN ('warrior', 'archer')),
    level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1 AND level <= 200),
    
    -- Stats de base Dofus-like
    vitality INTEGER NOT NULL DEFAULT 10 CHECK (vitality >= 0),
    wisdom INTEGER NOT NULL DEFAULT 10 CHECK (wisdom >= 0),
    strength INTEGER NOT NULL DEFAULT 10 CHECK (strength >= 0),
    intelligence INTEGER NOT NULL DEFAULT 10 CHECK (intelligence >= 0),
    chance INTEGER NOT NULL DEFAULT 10 CHECK (chance >= 0),
    agility INTEGER NOT NULL DEFAULT 10 CHECK (agility >= 0),
    
    -- Progression
    experience BIGINT NOT NULL DEFAULT 0 CHECK (experience >= 0),
    
    -- Position dans le monde
    map_x INTEGER NOT NULL DEFAULT 0,
    map_y INTEGER NOT NULL DEFAULT 0,
    pos_x INTEGER NOT NULL DEFAULT 15 CHECK (pos_x >= 0 AND pos_x < 30),
    pos_y INTEGER NOT NULL DEFAULT 15 CHECK (pos_y >= 0 AND pos_y < 30),
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Index pour optimiser les requêtes
CREATE INDEX idx_characters_user_id ON characters(user_id);
CREATE INDEX idx_characters_name ON characters(name);
CREATE INDEX idx_characters_last_login ON characters(last_login DESC);
CREATE INDEX idx_characters_map_position ON characters(map_x, map_y);

-- Contrainte pour limiter le nombre de personnages par utilisateur (5 max comme Dofus)
-- Note: Cette contrainte sera vérifiée côté application car PostgreSQL ne permet pas facilement de limiter le nombre de lignes par groupe

-- Trigger pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_characters_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_characters_updated_at
    BEFORE UPDATE ON characters
    FOR EACH ROW
    EXECUTE FUNCTION update_characters_updated_at();

-- Commentaires pour la documentation
COMMENT ON TABLE characters IS 'Table des personnages de joueurs';
COMMENT ON COLUMN characters.class IS 'Classe du personnage: warrior, archer';
COMMENT ON COLUMN characters.level IS 'Niveau du personnage (1-200)';
COMMENT ON COLUMN characters.vitality IS 'Vitalité (influence les PV)';
COMMENT ON COLUMN characters.wisdom IS 'Sagesse (influence les PM)';
COMMENT ON COLUMN characters.strength IS 'Force (dommages corps à corps)';
COMMENT ON COLUMN characters.intelligence IS 'Intelligence (dommages sorts)';
COMMENT ON COLUMN characters.chance IS 'Chance (dommages distance)';
COMMENT ON COLUMN characters.agility IS 'Agilité (initiative, esquive)';
COMMENT ON COLUMN characters.pos_x IS 'Position X sur la map (0-29)';
COMMENT ON COLUMN characters.pos_y IS 'Position Y sur la map (0-29)'; 