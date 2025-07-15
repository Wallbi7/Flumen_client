# 🛠️ Contexte Technique - Flumen MMORPG

## 🏗️ Architecture système

### **Stack technique OBLIGATOIRE**

#### Backend (Go)
- **Langage** : Go 1.21+ (dernière version stable)
- **Framework HTTP** : Fiber v2 (performance optimisée)
- **Communication** : WebSocket exclusivement via `gorilla/websocket`
- **Base de données** : PostgreSQL (driver `pgx` + ORM `GORM`)
- **Cache/Pub-Sub** : Redis via `go-redis/redis/v9`
- **Sérialisation** : JSON (phase 1) → MessagePack (phase 2)

#### Frontend (Godot 4.4.1)
- **Langage** : GDScript
- **Network** : WebSocketMultiplayerPeer
- **Architecture** : Scènes modulaires avec autoloads
- **Managers** : GameManager, AuthManager, NetworkManager

### 🔧 Patterns et conventions

#### Règles de concurrence (Go)
- **1 joueur = 1 goroutine** dédiée
- **États partagés** : protégés par mutex OU channels
- **Pattern Actor Model** pour les entités
- **Pas de variables globales** mutables

#### Protocol WebSocket
```json
{
  "type": "move|attack|chat|...",
  "data": {},
  "timestamp": 1234567890
}
```

### 🚀 Configuration déploiement

#### Ports réseau
- **Game Server** : 9090
- **Redis** : 6379
- **PostgreSQL** : 5432

#### Serveur de production
- **Adresse** : `server.flumen.local`
- **Environnement** : Production/Dev (pas de Docker)

### 📊 Objectifs de performance

- **Latence WebSocket** : < 50ms (95e percentile)
- **Tick rate serveur** : 20 Hz minimum
- **Démarrage cold start** : < 5 secondes
- **Mémoire par joueur** : < 1MB
- **CPU** : 1 core pour 500 joueurs connectés

### 🔍 Monitoring et observabilité

- **Profiling** : pprof intégré
- **Monitoring** : Prometheus metrics sur `/metrics`
- **Logs** : Format JSON structuré (zerolog)
- **Dashboard** : Interface web sur `/dashboard`
