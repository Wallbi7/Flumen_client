-- Migration pour supprimer la table characters
DROP TRIGGER IF EXISTS trigger_characters_updated_at ON characters;
DROP FUNCTION IF EXISTS update_characters_updated_at();
DROP TABLE IF EXISTS characters; 