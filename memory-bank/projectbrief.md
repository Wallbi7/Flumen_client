# 🌊 Flumen - MMORPG 2D Isométrique

## 📋 Vue d'ensemble du projet

**Flumen** est un MMORPG 2D isométrique inspiré de Dofus, développé avec une architecture moderne et scalable.

### 🎯 Objectifs principaux
- **2500+ joueurs simultanés**
- **Déplacement case par case** tactique
- **Combat tour par tour** stratégique  
- **Système de maps interconnectées** infini
- **Architecture évolutive** vers microservices

### 🏗️ Architecture technique
- **Client** : Godot 4.4.1 (GDScript)
- **Serveur** : Go avec Fiber v2
- **Base de données** : PostgreSQL
- **Cache/Pub-Sub** : Redis
- **Communication** : WebSocket exclusivement

### 🚀 État actuel
- ✅ Système d'authentification JWT
- ✅ Système de maps scalable (grille infinie)
- ✅ Multijoueur temps réel WebSocket
- ✅ Mouvement synchronisé case par case
- 🔧 **Problème actuel** : Connexion client-serveur (erreur 401)

### 🎯 Objectif alpha
Recréer l'expérience Dofus 1.29 avec fonctionnalités modernes et architecture scalable.
