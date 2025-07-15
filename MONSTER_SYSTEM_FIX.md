# 🐉 SYSTÈME DE MONSTRES - CORRECTION ET GUIDE

## ❌ **Problème Identifié**
L'erreur `Invalid call. Nonexistent function 'get_token' in base 'Node (AuthManager.gd)'` indique que la fonction `get_token()` n'existe pas dans `AuthManager.gd`.

## ✅ **Solution Appliquée**
**Correction dans `GameManager.gd` ligne 766:**
```gdscript
# AVANT (incorrect)
var token = auth_manager.get_token()

# APRÈS (correct)
var token = auth_manager.get_access_token()
```

## 🔧 **Améliorations Apportées**

### 1. **Sprite Temporaire pour Monstres**
- Remplacé `Sprite2D` par `ColorRect` pour éviter les problèmes de texture
- Couleurs différentes selon le type de monstre
- Taille adaptée selon le niveau

### 2. **Script de Test**
- Créé `test_monsters.gd` pour valider le système
- Scène de test `TestMonsters.tscn` 
- Tests automatiques de création, attaque, et mort

### 3. **Serveur Opérationnel**
- MonsterManager initialisé avec succès
- Spawn automatique toutes les 30 secondes
- API endpoints fonctionnels

## 🎮 **Comment Tester**

### Option 1: Jeu Normal
1. Lancer le serveur : `.\api.exe`
2. Lancer Godot et jouer normalement
3. Changer de map vers `map_1_0` (plaines)
4. Les monstres devraient apparaître automatiquement

### Option 2: Test Isolé
1. Ouvrir `TestMonsters.tscn` dans Godot
2. Lancer la scène
3. Regarder la console pour les résultats
4. Un monstre de test devrait apparaître et être attaqué

## 🗺️ **Configuration des Zones**

| Map ID | Zone | Monstres | Niveaux |
|--------|------|----------|---------|
| `map_0_0` | Village d'Astrub | Aucun (zone sûre) | - |
| `map_1_0` | Plaines d'Astrub | Tofu, Bouftou | 1-2 |
| `map_0_1` | Forêt d'Amakna | Larve, Prespic, Abeille | 2-5 |
| `map_0_-1` | Montagnes de Cania | Sanglier, Bouftou | 3-6 |

## 🎯 **Fonctionnalités Implémentées**

### Serveur (Go)
- ✅ 6 types de monstres avec stats équilibrées
- ✅ Système de zones avec règles de spawn
- ✅ Spawn automatique intelligent
- ✅ API REST complète
- ✅ Gestion des niveaux et scaling

### Client (Godot)
- ✅ Classe Monster avec composants visuels
- ✅ Chargement automatique via GameManager
- ✅ Interactions (clic gauche/droit)
- ✅ Système de dégâts et mort
- ✅ Animations et feedback visuel

## 🚀 **Prochaines Étapes**
1. **Combat tour par tour** complet
2. **IA des monstres** (mouvement, attaque)
3. **Système de sorts** pour monstres
4. **Butin et récompenses**
5. **Sprites graphiques** finaux

## 🔍 **Débogage**
Si les monstres n'apparaissent pas :
1. Vérifier que le serveur fonctionne (`MonsterManager initialisé`)
2. Vérifier le token d'authentification
3. Regarder les logs Godot pour les erreurs HTTP
4. Tester avec la scène `TestMonsters.tscn`

**Le système de base est fonctionnel ! 🎉** 