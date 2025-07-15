# 🏗️ Architecture Technique - Flumen

## 📋 Vue d'ensemble

Flumen utilise une **architecture client-serveur** avec communication **WebSocket** temps réel, conçue pour supporter **2500+ joueurs simultanés** avec une latence minimale.

## 🎮 Architecture Client (Godot 4.4.1)

### **Autoloads (Singletons)**
```gdscript
# Gestionnaires globaux accessibles partout
AuthManager     # 🔐 Authentification JWT
GameManager     # 🎮 Gestionnaire central du jeu
ServerConfig    # ⚙️ Configuration serveur
```

### **Système de Scènes**
```
LoginScene.tscn     # 🚪 Écran de connexion
main.tscn          # 🏠 Scène principale du jeu
├── WebSocketManager # 🌐 Communication serveur
├── Camera2D        # 📷 Caméra adaptative
└── UI              # 🖼️ Interface utilisateur
```

### **Architecture des Maps**
```gdscript
# Système de grille infinie
map_X_Y.tscn        # 🗺️ Scène de map individuelle
├── TileMap         # 🧱 Décor et collisions
├── SpawnPoint      # 📍 Point d'apparition
└── TransitionArea  # 🔄 Zones de transition automatiques
```

### **Flux de Données Client**
```
1. LoginScene → AuthManager → JWT Token
2. main.tscn → GameManager → WebSocketManager
3. WebSocket → Hub Serveur → Autres Joueurs
4. Player Input → GameManager → Serveur Sync
```

## 🖥️ Architecture Serveur (Go)

### **Structure Modulaire**
```go
cmd/api/main.go              // 🚀 Point d'entrée
internal/
├── auth/                    // 🔐 JWT & Sécurité
│   └── jwt.go
├── database/                // 💾 Couche données
│   ├── postgres.go
│   ├── user_repository.go
│   └── character_repository.go
├── game/                    // 🎮 Logique métier
│   ├── hub.go              // 🏢 Gestionnaire connexions
│   └── player_session.go   // 👤 Session joueur
├── handlers/               // 🌐 API & WebSocket
│   ├── auth_handler.go
│   └── game_handler.go
└── config/                 // ⚙️ Configuration
    └── config.go
```

### **Pattern Actor Model**
```go
// Chaque joueur = 1 goroutine dédiée
type PlayerSession struct {
    Hub      *Hub
    Conn     *websocket.Conn
    Send     chan []byte
    UserID   string
    Username string
    X, Y     float64
    MapID    string
}
```

### **Communication WebSocket**
```json
{
  "type": "player_move|change_map|chat|combat",
  "data": {
    "user_id": "uuid",
    "x": 100.5,
    "y": 200.3,
    "map_id": "map_1_0"
  }
}
```

## 🔄 Flux de Communication

### **Changement de Map**
```
1. Player → TransitionArea → send_change_map_request()
2. WebSocket → {"type": "change_map", "data": {"map_id": "map_1_0"}}
3. Serveur → Validation → Calcul spawn position
4. Serveur → {"type": "map_changed", "data": {"spawn_x": 100, "spawn_y": 538}}
5. Client → GameManager._on_map_changed() → load_map()
```

## 🗄️ Base de Données PostgreSQL

```sql
-- Table utilisateurs
users (
    id UUID PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255)
);

-- Table personnages
characters (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    name VARCHAR(50),
    class VARCHAR(20),
    level INTEGER DEFAULT 1,
    map_id VARCHAR(20) DEFAULT 'map_0_0',
    pos_x FLOAT DEFAULT 758.0,
    pos_y FLOAT DEFAULT 605.0
);
```

## 🚀 Configuration Production

```yaml
Host: server.flumen.local (192.168.1.70)
Game Port: 9090
Database: PostgreSQL:5432
Cache: Redis:6379

Objectifs:
- 2500+ joueurs simultanés
- Latence WebSocket <50ms
- Mémoire <1MB par joueur
```

---

Architecture optimisée pour **performance** et **scalabilité**.
