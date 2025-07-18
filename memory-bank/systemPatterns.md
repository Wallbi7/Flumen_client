# 📦 Système d'Inventaire (Inspiré de Dofus)

Ce document décrit l'architecture du système d'inventaire côté serveur. L'objectif est de créer un système robuste, extensible et où le serveur est l'unique source de vérité.

## 🏗️ Composants Principaux

### 1. `ItemTemplate` (Le Modèle d'Objet)
C'est la définition maîtresse de chaque objet existant dans le jeu.
- **Source :** `internal/models/item.go` -> `struct ItemTemplate`
- **Table DB :** `item_templates`

| Champ | Description | Type | Exemple |
|---|---|---|---|
| `ID` | Identifiant unique du modèle | `UUID` | `gen_random_uuid()` |
| `Name` | Nom de l'objet | `string` | "Coiffe du Bouftou" |
| `ItemType` | Type d'objet | `enum` | `EQUIPMENT`, `CONSUMABLE`... |
| `LevelRequirement` | Niveau minimum pour équiper/utiliser | `int` | `20` |
| `Stackable` | L'objet peut-il être empilé ? | `bool` | `true` (pour les ressources) |
| `Effects` | Bonus de stats de base | `JSONB` | `{"strength": 10, "vitality": 25}` |

### 2. `InventoryItem` (L'Instance d'Objet)
C'est l'objet réel qui se trouve dans l'inventaire d'un joueur.
- **Source :** `internal/models/item.go` -> `struct InventoryItem`
- **Table DB :** `inventory_items`

| Champ | Description | Type | Exemple |
|---|---|---|---|
| `ID` | Identifiant unique de CET objet | `UUID` | `gen_random_uuid()` |
| `CharacterID` | Propriétaire de l'objet | `UUID` | (ID du personnage) |
| `ItemTemplateID` | Lien vers le modèle d'objet | `UUID` | (ID de la Coiffe du Bouftou) |
| `Quantity` | Nombre d'objets si empilable | `int` | `100` (pour 100 bois de frêne) |
| `InstanceStats` | Stats uniques (forgemagie) | `JSONB` | `{"strength": 12, "vitality": 28}` |
| `EquippedSlot` | Slot où l'objet est équipé | `string` | `HEAD` (ou `NULL` si dans le sac) |

---

## 🛡️ Slots d'Équipement
Le système gère les slots d'équipement suivants, définis dans `internal/models/item.go`.
- `HEAD` (Tête)
- `CHEST` (Torse/Cape)
- `WEAPON` (Arme)
- `AMULET` (Amulette)
- `RING` (Anneau) - Logique spéciale pour 2 anneaux
- `BELT` (Ceinture)
- `BOOTS` (Bottes)
- `PET` (Familier)
- `MOUNT` (Monture)

---

## ⚙️ Logique Métier

### Recalcul des Stats
- **Fichier :** `internal/models/character.go` -> `RecalculateStats()`
- **Processus :**
  1. Partir des `BaseStats` du personnage.
  2. Itérer sur tous les `InventoryItem` où `EquippedSlot` n'est pas `NULL`.
  3. Appliquer les `Effects` de chaque objet équipé pour obtenir les `ComputedStats`.
  4. Les `InstanceStats` (si elles existent) remplacent les `Effects` de base de l'objet.
- **Règle d'or :** Ce calcul est **TOUJOURS** fait côté serveur. Le client ne fait qu'afficher le résultat.

### Contraintes
- Un seul objet par slot, sauf pour les anneaux.
- Les conditions (`LevelRequirement`, etc.) doivent être vérifiées par le serveur avant d'autoriser l'équipement.

---

# ⚔️ Système de Combat Tour par Tour

Ce document décrit l'architecture du système de combat, conçu pour être modulaire et géré entièrement côté serveur.

## 🏗️ Composants Clés

| Composant | Fichier | Rôle |
|---|---|---|
| `CombatState` | `models/combat_state.go` | La structure de données qui représente un "snapshot" complet d'un combat à un instant T. C'est cet objet qui est envoyé aux clients. |
| `TurnManager` | `game/turn_manager.go` | Gère la logique des tours : calcul de l'initiative, ordre de jeu, passage au tour suivant, réinitialisation des stats de tour. |
| `ActionHandler`| `game/action_handler.go` | Valide et applique les actions des joueurs (déplacement, sort...). Il vérifie les coûts en PA/PM et les conditions de l'action. |
| `CombatManager`| `game/combat_manager.go` | L'orchestrateur global. Il gère toutes les instances de combat actives, reçoit les requêtes d'action et utilise les autres managers pour mettre à jour l'état du combat. |
| `CombatHandler`| `handlers/combat_handler.go`| L'interface API (REST ou WebSocket) qui expose la logique du `CombatManager` au monde extérieur. |

## 🌊 Flux d'un Combat (Séquence)

1.  **Création du Combat :**
    -   Un client envoie une requête à `POST /combat` avec les ID des personnages.
    -   `CombatHandler` reçoit la requête.
    -   Il appelle `CombatManager.CreateNewCombat()`.
    -   Le `CombatManager` :
        -   Crée une instance de `CombatState`.
        -   Peuple les `Combatants` avec les stats des personnages.
        -   Appelle `TurnManager.StartCombat()` pour calculer l'initiative et définir le premier tour.
        -   Stocke le nouveau `CombatState` dans sa liste de combats actifs.
    -   Le `CombatState` initial est renvoyé au client.

2.  **Déroulement d'un Tour :**
    -   Le client du joueur dont c'est le tour envoie une action à `POST /combat/:id/action`.
    -   `CombatHandler` reçoit la requête.
    -   Il appelle `CombatManager.ProcessAction()`.
    -   Le `CombatManager` :
        -   Récupère le bon `CombatState`.
        -   Vérifie que c'est bien le tour de l'acteur.
        -   Appelle le `ActionHandler` approprié (ex: `HandleMoveAction`).
        -   Le `ActionHandler` valide l'action (coût en PM, etc.) et met à jour le `CombatState` (nouvelle position, PM restants...).
    -   Le `CombatState` mis à jour est renvoyé au client.

3.  **Fin du Tour :**
    -   Le joueur passe son tour (ou le timer expire).
    -   Une action `PASS_TURN` est envoyée.
    -   Le `CombatManager` appelle `TurnManager.NextTurn()`.
    -   Le `TurnManager` met à jour l'index du tour, réinitialise les PA/PM du nouveau joueur et le cycle recommence.

## ⚖️ Règles Fondamentales
-   **Source de Vérité :** Le serveur est le seul et unique maître de l'état du combat. Les calculs (dégâts, PM restants, etc.) sont faits sur le serveur.
-   **Communication :** Le client envoie des "intentions" d'action. Le serveur les valide, les applique, et renvoie le nouvel état de vérité (`CombatState`). Le client ne fait que refléter cet état.
-   **État :** Le `CombatState` est conçu pour être la seule information nécessaire au client pour afficher le combat.

## Architecture des Systèmes

### Système de Combat (Corrigé le 19/01/2025)

#### Architecture Serveur-Client
- **Serveur**: Les messages `initiate_combat` doivent être transmis au hub via le canal Broadcast, PAS traités localement dans player_session
- **Hub**: Crée un CombatState complet via CombatManager et envoie l'état entier au client
- **Client**: CombatManager utilise WebSocketManager (PAS NetworkManager) avec signaux connectés

#### Flux de Combat
1. Clic sur monstre → `initiate_combat` envoyé au serveur
2. PlayerSession → Forward au Hub via Broadcast
3. Hub → Crée CombatState complet avec positions, stats, ordre de tour
4. Hub → Envoie `combat_started` avec état complet
5. Client → Désactive mouvement joueur, affiche grille avec combattants
6. Combat → Actions échangées via `combat_update`
7. Fin → `combat_ended` réactive mouvement

#### Points Clés
- **Mouvement**: Désactivé via `player.movement_enabled = false` et vérification `GameState.IN_COMBAT`
- **Signaux WebSocket**: `combat_update`, `combat_action_response`, `combat_ended` doivent être définis
- **CombatManager**: Cherche WebSocketManager dans la scène principale ou via GameManager
