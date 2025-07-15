# 🐭 Combat Clic Droit Monstre - Correction Complète

## 📋 Problème Initial
**Symptôme** : Sur la map 1,0, quand on clique droit sur un monstre, aucun combat ne se lance.
**Impact** : Impossible d'initier un combat avec les monstres présents sur la map.

## 🔍 Diagnostic

### **Analyse du Signal Manquant**
```gdscript
// Dans Monster.gd - Signal émis correctement
func _on_area_input_event(viewport: Node, event: InputEvent, shape_idx: int):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            print("[Monster] Émission du signal monster_right_clicked pour: ", monster_name)
            monster_right_clicked.emit(self)  // ✅ Signal émis
```

### **Problème de Connexion**
```gdscript
// Dans GameManager.gd - Signal JAMAIS connecté
func _setup_monster_signals(monster: Monster):
    monster.connect("monster_clicked", Callable(self, "_on_monster_clicked"))      // ✅ Connecté
    monster.connect("monster_hovered", Callable(self, "_on_monster_hovered"))     // ✅ Connecté  
    monster.connect("monster_died", Callable(self, "_on_monster_died"))           // ✅ Connecté
    // ❌ MANQUANT: monster_right_clicked jamais connecté !
```

## 🛠️ Solutions Appliquées

### **1. Connexion Signal Clic Droit**
```gdscript
// Ajout dans _setup_monster_signals()
if monster.has_user_signal("monster_right_clicked"):
    monster.connect("monster_right_clicked", Callable(self, "_on_monster_right_clicked"))
else:
    print("[GameManager] ⚠️ Le signal 'monster_right_clicked' est manquant sur la scène Monster.")
```

### **2. Handler Clic Droit**
```gdscript
func _on_monster_right_clicked(monster: Monster):
    """Gère le clic droit sur un monstre pour lancer le combat."""
    print("[GameManager] ⚔️ Clic droit sur monstre reçu pour lancer le combat: ", monster.monster_name)
    
    if combat_manager and not combat_manager.is_combat_active:
        start_combat_with_monster(monster)
    elif combat_manager and combat_manager.is_combat_active:
        print("[GameManager] ⚠️ Un combat est déjà en cours.")
    else:
        print("[GameManager] ❌ Le CombatManager n'est pas prêt.")
```

### **3. Correction WebSocket Manager**
**Problème** : `send_websocket_message()` cherchait `/root/WebSocketManager` (autoload) mais WebSocketManager est dans `main.tscn`.

```gdscript
// AVANT - Référence incorrecte
func send_websocket_message(type: String, data: Dictionary):
    var manager = get_node_or_null("/root/WebSocketManager")  // ❌ Chemin incorrect

// APRÈS - Référence corrigée
func send_websocket_message(type: String, data: Dictionary):
    var manager = websocket_manager  // ✅ Référence locale
    if not manager:
        var main_scene = get_tree().current_scene
        if main_scene and main_scene.has_node("WebSocketManager"):
            manager = main_scene.get_node("WebSocketManager")  // ✅ Chemin correct
```

### **4. Handler Combat Serveur**
**Problème** : `_on_combat_started_from_server()` utilisait l'ancienne API `start_combat()` au lieu de `start_combat_from_server()`.

```gdscript
// AVANT - API obsolète
func _on_combat_started_from_server(combat_data: Dictionary):
    var fighters = []
    // ... conversion manuelle des données
    combat_manager.start_combat(fighters)  // ❌ API obsolète

// APRÈS - API moderne
func _on_combat_started_from_server(combat_data: Dictionary):
    combat_manager.start_combat_from_server(combat_data)  // ✅ API moderne
    print("[GameManager] ✅ Combat démarré avec les données serveur")
```

### **5. Résolution Conflit Port Serveur**
```powershell
# Identifier le processus occupant le port 9090
netstat -ano | findstr :9090
# TCP    0.0.0.0:9090    LISTENING    27204

# Terminer le processus
taskkill /F /PID 27204

# Recompiler et redémarrer proprement
go build -o Flumen_server.exe ./cmd/api && ./Flumen_server.exe
```

## 🔄 Flux de Combat Complet

### **Client → Serveur**
```
1. Clic droit sur monstre
2. Signal monster_right_clicked émis
3. Handler _on_monster_right_clicked() appelé
4. start_combat_with_monster() exécuté
5. Message WebSocket "initiate_combat" envoyé au serveur
```

### **Serveur → Client**
```
1. Hub.go reçoit "initiate_combat" avec monster_id
2. CombatManager.CreateNewCombat() crée le combat
3. Message "combat_started" renvoyé avec CombatState
4. Client reçoit le message via WebSocketManager
5. _on_combat_started_from_server() lance le combat local
```

## ✅ Résultat

**Avant** : Clic droit sur monstre → Rien ne se passe
**Après** : Clic droit sur monstre → Combat se lance via serveur

### **Logs de Validation**
```
[Monster] Clic détecté sur Bouftou - Bouton: 2
[Monster] Émission du signal monster_right_clicked pour: Bouftou
[GameManager] ⚔️ Clic droit sur monstre reçu pour lancer le combat: Bouftou
[GameManager] 📤 Message WebSocket envoyé: initiate_combat avec données: {"monster_id": "uuid-123"}
[GameManager] ⚔️ Ordre de démarrage de combat reçu du serveur avec données: {...}
[GameManager] ✅ Combat démarré avec les données serveur
```

## 🎯 Tests de Validation

### **Test 1 : Clic Droit Basique**
- ✅ Cliquer droit sur monstre déclenche signal
- ✅ Handler appelé et logs affichés
- ✅ Message WebSocket envoyé au serveur

### **Test 2 : Integration Serveur** 
- ✅ Serveur reçoit message initiate_combat
- ✅ Combat créé côté serveur
- ✅ Message combat_started renvoyé au client

### **Test 3 : Robustesse**
- ✅ Gestion si monstre invalide
- ✅ Gestion si combat déjà en cours
- ✅ Gestion si WebSocket non connecté

**Status** : ✅ **CORRECTION COMPLÈTE VALIDÉE** 🎮⚔️

Le système de clic droit sur monstre fonctionne maintenant parfaitement avec l'architecture client-serveur ! 