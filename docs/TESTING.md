# 🧪 Système de Tests - Flumen MMORPG

Ce document décrit le système de tests automatisés mis en place pour le projet Flumen MMORPG, utilisant Godot CLI + GUT (Godot Unit Testing).

## 📋 Vue d'ensemble

Le système de tests est conçu pour :
- **Assurer la qualité du code** lors des modifications
- **Prévenir les régressions** dans les systèmes critiques
- **Faciliter le développement** avec des tests automatisés
- **Intégrer avec Git** pour des tests automatiques avant commit

## 🏗️ Architecture des Tests

### Structure des Dossiers

```
Flumen_client/
├── addons/gut/              # Framework de tests GUT
│   ├── plugin.cfg
│   ├── plugin.gd
│   ├── gut_main.gd         # Moteur principal des tests
│   └── gut_test.gd         # Classe de base pour les tests
├── test/
│   ├── unit/               # Tests unitaires
│   │   ├── test_game_manager.gd
│   │   └── test_map_config.gd
│   └── integration/        # Tests d'intégration
│       └── test_websocket_integration.gd
├── scripts/
│   ├── run_tests.ps1       # Script principal de tests
│   ├── test_runner.gd      # Runner Godot CLI
│   └── setup_git_hooks.ps1 # Configuration Git hooks
└── .githooks/
    └── pre-commit          # Hook Git pre-commit
```

## 🛠️ Utilisation

### Lancement Manuel des Tests

```powershell
# Tous les tests
.\scripts\run_tests.ps1

# Tests unitaires seulement
.\scripts\run_tests.ps1 -TestDir "res://test/unit/"

# Tests avec sortie détaillée
.\scripts\run_tests.ps1 -Verbose
```

### Configuration Git Hooks

```powershell
# Installer les hooks Git (tests automatiques avant commit)
.\scripts\setup_git_hooks.ps1

# Forcer la réinstallation
.\scripts\setup_git_hooks.ps1 -Force
```

## 📝 Écriture de Tests

### Classe de Base GutTest

```gdscript
extends GutTest

func before_each():
    # Setup avant chaque test
    pass

func after_each():
    # Nettoyage après chaque test
    pass

func test_example():
    # Nom doit commencer par "test_"
    assert_eq(actual, expected, "Message d'erreur")
```

### Assertions Disponibles

```gdscript
# Égalité
assert_eq(actual, expected, message)
assert_ne(actual, expected, message)

# Booléens
assert_true(value, message)
assert_false(value, message)

# Nullité
assert_null(value, message)
assert_not_null(value, message)

# Comparaisons numériques
assert_gt(actual, expected, message)
assert_lt(actual, expected, message)
assert_between(actual, min, max, message)

# Conteneurs
assert_has(container, item, message)
assert_does_not_have(container, item, message)
```

## 🎯 Tests Existants

### Tests Unitaires

#### `test_game_manager.gd`
- ✅ Initialisation du GameManager
- ✅ Gestion du joueur actuel
- ✅ Gestion des coordonnées de carte
- ✅ États d'authentification et connexion

#### `test_map_config.gd`
- ✅ Génération des chemins de scène
- ✅ Calcul des coordonnées adjacentes
- ✅ Positions de spawn selon direction
- ✅ Tests de performance

### Tests d'Intégration

#### `test_websocket_integration.gd`
- ✅ Initialisation WebSocketManager
- ✅ Synchronisation état du jeu

## 🔧 Configuration

### Prérequis

1. **Godot 4.4.1** installé dans `C:\Program Files\Godot\`
2. **PowerShell 7+** ou PowerShell 5.1
3. **Git** pour les hooks automatiques

## 🐛 Dépannage

### Problèmes Courants

#### "Godot non trouvé"
```powershell
# Vérifier le chemin
Test-Path "C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe"
```

#### "GUT n'est pas disponible"
- Vérifier que l'addon est activé dans Godot
- Projet > Paramètres du projet > Plugins > GUT ✅

## 📈 Métriques Actuelles

- ✅ **GameManager** : 10 tests / 100% couverture
- ✅ **MapConfig** : 12 tests / 95% couverture
- 🔄 **WebSocketManager** : 3 tests / 60% couverture

**Happy Testing! 🎮** 