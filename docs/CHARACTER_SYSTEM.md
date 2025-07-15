# 🎮 Système de Personnages - Flumen MMORPG

## Vue d'ensemble

Le système de personnages de Flumen permet aux joueurs de créer, sélectionner et gérer leurs personnages dans l'univers du jeu. Il s'inspire du système de Dofus avec des classes distinctes et un système de stats complet.

## 🏗️ Architecture

### Composants Principaux

1. **Modèles de Données** (`internal/models/character.go`)
   - Structure `Character` avec stats complètes
   - Énumération des classes disponibles
   - Calculs de stats dérivées

2. **Repository** (`internal/database/character_repository.go`)
   - CRUD complet pour les personnages
   - Validation des contraintes métier
   - Gestion des positions et stats

3. **Handlers** (`internal/handlers/character_handler.go`)
   - API REST et WebSocket
   - Validation des requêtes
   - Gestion des erreurs

4. **Interface Client** (`game/ui/CharacterSelection.gd`)
   - Sélection visuelle des personnages
   - Création avec choix de classe
   - Gestion des slots (5 max)

## 📊 Classes Disponibles

### Guerrier (Warrior)
- **Rôle** : Tank/DPS corps à corps
- **Stats de base** :
  - Vitalité : 20 (PV élevés)
  - Force : 15 (Dommages corps à corps)
  - Agilité : 10 (Initiative moyenne)
- **Spécialités** : Armes lourdes, résistance

### Archer (Archer)
- **Rôle** : DPS à distance
- **Stats de base** :
  - Chance : 15 (Dommages distance)
  - Agilité : 15 (Initiative élevée)
  - Vitalité : 15 (PV moyens)
- **Spécialités** : Arcs, précision, mobilité

## 📈 Système de Stats

### Stats Primaires
- **Vitalité** : Détermine les Points de Vie (PV = Vitalité × 5 + Niveau × 2)
- **Sagesse** : Influence les Points de Mouvement et la résistance magique
- **Force** : Dommages des armes de corps à corps
- **Intelligence** : Dommages des sorts élémentaires
- **Chance** : Dommages des armes de jet et critique
- **Agilité** : Initiative, esquive, Points de Mouvement bonus

### Stats Dérivées
- **Points de Vie (PV)** : Vitalité × 5 + Niveau × 2
- **Points d'Action (PA)** : 6 de base (modifiable par équipements)
- **Points de Mouvement (PM)** : 3 de base + Agilité ÷ 50
- **Initiative** : Agilité + Niveau + aléatoire (en combat)

## 🎯 Progression

### Système de Niveaux
- **Niveaux** : 1 à 200
- **Expérience** : Courbe exponentielle (Niveau² × 100)
- **Gains par niveau** : +10% des stats de base de la classe

### Exemple de Progression (Guerrier)
```
Niveau 1 : Vitalité 20, Force 15
Niveau 2 : Vitalité 22, Force 16
Niveau 10 : Vitalité 40, Force 30
```

## 🌍 Positionnement

### Système de Coordonnées
- **Maps** : Grille infinie (map_X_Y)
- **Position locale** : 30×30 cases par map
- **Spawn par défaut** : Centre de la map (15, 15)

### Changements de Map
- Sauvegarde automatique de la position
- Synchronisation avec les autres joueurs
- Validation des transitions

## 🔧 API WebSocket

### Messages Client → Serveur

#### Récupérer les Personnages
```json
{
  "type": "get_characters",
  "data": {},
  "timestamp": 1234567890
}
```

#### Créer un Personnage
```json
{
  "type": "create_character",
  "data": {
    "name": "MonGuerrier",
    "class": "warrior"
  },
  "timestamp": 1234567890
}
```

#### Sélectionner un Personnage
```json
{
  "type": "select_character",
  "data": {
    "character_id": 123
  },
  "timestamp": 1234567890
}
```

#### Supprimer un Personnage
```json
{
  "type": "delete_character",
  "data": {
    "character_id": 123
  },
  "timestamp": 1234567890
}
```

### Messages Serveur → Client

#### Liste des Personnages
```json
{
  "type": "characters_list",
  "data": {
    "success": true,
    "characters": [
      {
        "id": 1,
        "name": "MonGuerrier",
        "class": "warrior",
        "level": 5,
        "vitality": 25,
        "strength": 20,
        "health_points": 135,
        "action_points": 6,
        "movement_points": 3
      }
    ],
    "classes": [
      {
        "id": "warrior",
        "name": "Guerrier",
        "description": "Combattant au corps à corps",
        "base_stats": {
          "vitality": 20,
          "strength": 15,
          "agility": 10
        }
      }
    ]
  }
}
```

#### Personnage Sélectionné
```json
{
  "type": "character_selected",
  "data": {
    "success": true,
    "character": {
      "id": 1,
      "name": "MonGuerrier",
      "class": "warrior",
      "level": 5,
      "map_x": 0,
      "map_y": 0,
      "pos_x": 15,
      "pos_y": 15
    }
  }
}
```

## 🛡️ Contraintes et Validations

### Nom de Personnage
- **Longueur** : 3-20 caractères
- **Caractères** : Lettres, chiffres, tirets
- **Unicité** : Nom unique sur le serveur
- **Validation** : Pas de mots interdits

### Limites
- **Maximum 5 personnages** par compte
- **Classes disponibles** : Guerrier, Archer (extensible)
- **Suppression** : Confirmation requise

### Sécurité
- **Authentification** : Token JWT requis
- **Autorisation** : Personnage appartient au joueur
- **Validation** : Toutes les données côté serveur

## 📁 Structure de Base de Données

### Table `characters`
```sql
CREATE TABLE characters (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    name VARCHAR(20) NOT NULL UNIQUE,
    class VARCHAR(20) NOT NULL CHECK (class IN ('warrior', 'archer')),
    level INTEGER NOT NULL DEFAULT 1,
    vitality INTEGER NOT NULL DEFAULT 10,
    wisdom INTEGER NOT NULL DEFAULT 10,
    strength INTEGER NOT NULL DEFAULT 10,
    intelligence INTEGER NOT NULL DEFAULT 10,
    chance INTEGER NOT NULL DEFAULT 10,
    agility INTEGER NOT NULL DEFAULT 10,
    experience BIGINT NOT NULL DEFAULT 0,
    map_x INTEGER NOT NULL DEFAULT 0,
    map_y INTEGER NOT NULL DEFAULT 0,
    pos_x INTEGER NOT NULL DEFAULT 15,
    pos_y INTEGER NOT NULL DEFAULT 15,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

### Index et Contraintes
- Index sur `user_id` pour les requêtes par utilisateur
- Index sur `name` pour l'unicité
- Index sur `(map_x, map_y)` pour les requêtes spatiales
- Trigger de mise à jour automatique `updated_at`

## 🚀 Déploiement

### Migration
```bash
# Appliquer la migration
migrate -path ./migrations -database "postgres://..." up

# Vérifier la structure
psql -d flumen -c "\d characters"
```

### Test
```bash
# Lancer le serveur de test
go run test_character_server.go

# Tester avec le client Godot
# Connecter depuis CharacterSelection.tscn
```

## 🔮 Évolutions Futures

### Phase 2 : Classes Avancées
- **Mage** : Intelligence, sorts élémentaires
- **Prêtre** : Sagesse, soins et buffs
- **Voleur** : Agilité, critique et furtivité

### Phase 3 : Personnalisation
- **Apparence** : Couleurs, équipements visuels
- **Sorts** : Arbre de compétences par classe
- **Métiers** : Artisanat, récolte, commerce

### Phase 4 : Social
- **Guildes** : Appartenance et avantages
- **Alignement** : Bon/Neutre/Mauvais
- **PvP** : Système d'honneur et récompenses

## 📚 Références

- [Modèle Character](../internal/models/character.go)
- [Interface CharacterSelection](../game/ui/CharacterSelection.gd)
- [Migration Database](../migrations/000003_create_characters_table.up.sql)
- [Serveur de Test](../test_character_server.go)

---

**Statut** : ✅ Implémenté et fonctionnel  
**Version** : 1.0.0  
**Dernière mise à jour** : Décembre 2024 