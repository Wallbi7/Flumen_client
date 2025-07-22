# Documentation API Quêtes (Flumen)

## Modèles principaux

### Quest
- `id` (UUID) : identifiant unique de la quête
- `name` (string) : nom de la quête
- `description` (string) : description narrative
- `required_level` (int) : niveau minimum requis
- `objectives_json` (JSONB) : liste des objectifs (voir QuestObjective)
- `reward_xp` (int) : expérience gagnée
- `reward_kamas` (int) : kamas gagnés
- `reward_item_id` (UUID, optionnel) : item de récompense
- `created_at`, `updated_at` (timestamp)

### QuestObjective
- `id` (UUID) : identifiant unique de l'objectif
- `quest_id` (UUID) : FK vers la quête
- `type` (string) : type d'objectif ('kill', 'collect', 'explore', 'talk')
- `target_id` (string) : cible (ex: monster type, item id, zone id)
- `quantity` (int) : quantité requise
- `description` (string)

### QuestProgress
- `id` (UUID) : identifiant unique de la progression
- `character_id` (UUID) : FK vers le personnage
- `quest_id` (UUID) : FK vers la quête
- `status` (string) : 'in_progress', 'completed'
- `progress_json` (JSONB) : état détaillé des objectifs
- `updated_at` (timestamp)

---

## Endpoints REST Quêtes

### 1. Lister toutes les quêtes
**GET** `/api/v1/quests`
- **Réponse :** tableau de Quest
- **Accès :** public

### 2. Accepter une quête
**POST** `/api/v1/quests/:id/accept`
- **Headers :** Authorization: Bearer <JWT>
- **Body :** (vide)
- **Réponse :** QuestProgress créé
- **Accès :** protégé (JWT)

### 3. Lister les quêtes d'un personnage
**GET** `/api/v1/characters/:charId/quests`
- **Headers :** Authorization: Bearer <JWT>
- **Réponse :** tableau de QuestProgress
- **Accès :** protégé (JWT)

---

## Statuts & Erreurs
- 401 Unauthorized : si JWT manquant ou invalide
- 404 Not Found : quête non trouvée
- 500 Internal Server Error : erreur serveur ou DB

---

## Exemples de payloads

### Quest (exemple)
```json
{
  "id": "b1c2...",
  "name": "Chasseur de Bouftous",
  "description": "Tuez 5 Bouftous pour prouver votre valeur.",
  "required_level": 1,
  "objectives_json": [
    { "type": "kill", "target_id": "bouftou", "quantity": 5, "description": "Tuer 5 Bouftous" }
  ],
  "reward_xp": 100,
  "reward_kamas": 50,
  "reward_item_id": null,
  "created_at": "...",
  "updated_at": "..."
}
```

### QuestProgress (exemple)
```json
{
  "id": "d2e3...",
  "character_id": "a1b2...",
  "quest_id": "b1c2...",
  "status": "in_progress",
  "progress_json": { "bouftou_kills": 3 },
  "updated_at": "..."
}
``` 