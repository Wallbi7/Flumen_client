# Corrections du Système de Combat Flumen

## Problèmes Identifiés

1. **Serveur**: Le message `initiate_combat` était traité localement dans `player_session.go` avec un simple TODO, au lieu d'être transmis au hub pour créer un vrai combat
2. **Client**: Le CombatManager cherchait un NetworkManager inexistant au lieu du WebSocketManager
3. **Client**: Les contrôles du joueur restaient actifs pendant le combat
4. **Client**: Les signaux WebSocket pour les mises à jour de combat n'étaient pas définis

## Corrections Apportées

### Côté Serveur (Go)

#### 1. player_session.go
- **Avant**: Traitement local avec réponse minimale `{monster_id, player_id, combat_id}`
- **Après**: Transmission du message au hub via le canal Broadcast
```go
case MsgInitiateCombat:
    // Transmettre le message au hub pour traitement centralisé
    messageBytes, err := json.Marshal(msg)
    if err != nil {
        log.Printf("Error marshalling initiate_combat message: %v", err)
        return
    }
    
    // Envoyer au hub via le canal Broadcast
    s.Hub.Broadcast <- &MessageFromPlayer{
        Session: s,
        Message: messageBytes,
    }
```

Le hub (`hub.go`) contient déjà la logique complète pour:
- Récupérer le monstre depuis MonsterManager
- Créer un CombatState complet via CombatManager
- Envoyer l'état complet au client

### Côté Client (Godot)

#### 1. CombatManager.gd
- **Remplacé** `network_manager` par `websocket_manager`
- **Ajouté** recherche du WebSocketManager dans la scène principale et via GameManager
- **Implémenté** `_connect_network_signals()` pour connecter les signaux de combat
- **Ajouté** les callbacks pour traiter les messages du serveur:
  - `_on_combat_update_from_server()`
  - `_on_combat_action_response()`
  - `_on_combat_ended_from_server()`

#### 2. player.gd
- **Ajouté** variable `movement_enabled` et référence au GameManager
- **Ajouté** vérification de l'état du jeu dans `_unhandled_input()`
- **Ajouté** méthode `set_movement_enabled()` pour contrôler le mouvement
```gdscript
# Vérifier si le jeu est en mode combat
if game_manager and game_manager.current_state == game_manager.GameState.IN_COMBAT:
    print("[Player] ⚠️ Mouvement bloqué - Mode combat actif")
    return
```

#### 3. GameManager.gd
- **Ajouté** méthode `get_websocket_manager()` pour exposer la référence
- **Modifié** `_on_combat_started_from_server()` pour désactiver le mouvement du joueur
- **Utilisé** `_on_local_combat_ended()` existant qui réactive déjà le mouvement

#### 4. WebSocketManager.gd
- **Ajouté** signaux manquants:
  - `signal combat_update(update_data)`
  - `signal combat_action_response(response_data)`
  - `signal combat_ended(end_data)`
- **Ajouté** handlers pour ces messages dans le match:
  - `"combat_update": _handle_combat_update(data.data)`
  - `"combat_action_response": _handle_combat_action_response(data.data)`
  - `"combat_ended": _handle_combat_ended(data.data)`
- **Implémenté** les méthodes `_handle_*` correspondantes

## Flux de Combat Corrigé

1. **Clic sur monstre** → Client envoie `initiate_combat`
2. **PlayerSession** → Transmet au Hub via Broadcast
3. **Hub** → Crée CombatState complet et renvoie `combat_started`
4. **Client** → Reçoit l'état complet, démarre le combat, désactive mouvement
5. **Combat** → Échanges d'actions et mises à jour via WebSocket
6. **Fin** → `combat_ended` reçu, mouvement réactivé, retour IN_GAME

## Tests Nécessaires

1. Vérifier que le serveur démarre sans erreur
2. Cliquer sur un monstre et vérifier:
   - La grille de combat s'affiche avec les combattants
   - Le joueur ne peut plus se déplacer sur la carte
   - Les données de combat sont complètes (positions, stats, etc.)
3. Terminer un combat et vérifier:
   - Le mouvement est réactivé
   - L'état revient à IN_GAME

## Notes

- Le système de retry automatique pour la connexion WebSocket a été ajouté dans GameManager
- Les données de test de combat ont été mises à jour pour correspondre au nouveau format CombatState 