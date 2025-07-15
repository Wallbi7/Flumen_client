-- Warrior: Niveau 1 à 10
INSERT INTO spell_templates
(id, class, name, description, min_level, pa_cost, range_min, range_max, area, effects)
VALUES
-- Slash (Niv 1)
('WAR_SLASH', 'Warrior', 'Slash', 'Coup dʼépée de base', 1, 3, 1, 1, 'SELF',
 '{"v":1,"data":[{"type":"Damage","element":"Neutral","value":40}]}'),
-- Shield Bash (Niv 5)
('WAR_SHIELD_BASH', 'Warrior', 'Shield Bash', 'Coup de bouclier qui étourdit', 5, 4, 1, 1, 'SELF',
 '{"v":1,"data":[{"type":"Damage","element":"Neutral","value":30},{"type":"Stun","duration":1}]}'),
-- War Cry (Niv 10)
('WAR_WAR_CRY', 'Warrior', 'War Cry', 'Cri de guerre qui booste la Force', 10, 4, 0, 0, 'SELF',
 '{"v":1,"data":[{"type":"Buff","stat":"Force","percent":20,"duration":2}]}'),
-- Archer: Niveau 1 à 10
-- Power Shot (Niv 1)
('ARC_POWER_SHOT', 'Archer', 'Power Shot', 'Tir puissant mono-cible', 1, 3, 3, 6, 'SINGLE',
 '{"v":1,"data":[{"type":"Damage","element":"Neutral","value":35}]}'),
-- Piercing Arrow (Niv 5)
('ARC_PIERCING_ARROW', 'Archer', 'Piercing Arrow', 'Flèche qui traverse les armures', 5, 5, 1, 5, 'LINE',
 '{"v":1,"data":[{"type":"Damage","element":"Neutral","value":45},{"type":"Pierce","percent":100}]}'),
-- Hail of Arrows (Niv 10)
('ARC_HAIL_ARROWS', 'Archer', 'Hail of Arrows', 'Pluie de flèches en cône', 10, 6, 2, 5, 'CONE',
 '{"v":1,"data":[{"type":"Damage","element":"Neutral","value":25}]}'); 