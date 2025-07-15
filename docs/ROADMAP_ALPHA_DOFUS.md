# 🗺️ Roadmap Alpha Flumen - Version Dofus 1.29

## 📋 Vue d'ensemble

Cette roadmap détaille les étapes pour transformer Flumen d'un prototype fonctionnel vers une **version alpha complète** comparable à **Dofus 1.29**. L'objectif est d'avoir un MMORPG jouable avec toutes les mécaniques de base.

## 🎯 Objectifs Alpha

- **🎮 Gameplay complet** : Personnages, combat, inventaire, sorts
- **🌍 Monde jouable** : Maps, PNJ, quêtes, donjons
- **👥 Multijoueur stable** : 100+ joueurs simultanés minimum
- **💰 Économie fonctionnelle** : Boutiques, échanges, artisanat
- **⚔️ PvP de base** : Combat joueur vs joueur
- **🏰 Système social** : Guildes, chat, amis

## 📊 État Actuel (Acquis)

### ✅ **Fondations Solides**
- **Authentification JWT** sécurisée
- **Système de maps** scalable infini
- **WebSocket** temps réel stable
- **Déplacement** case par case fluide
- **Architecture** client/serveur robuste
- **Tests automatisés** (105 tests, 100% réussite)

## 🚀 Phases de Développement

### **Phase 1 : Système de Personnages Core** 🎭
*Durée estimée : 3-4 semaines*

#### 🎯 Objectifs
- Système de classes (Iop, Cra, Eniripsa, Osamodas, etc.)
- Stats de base (Vie, PA, PM, caractéristiques)
- Système de niveaux et expérience
- Équipements de base

#### 🎮 Mécaniques Dofus 1.29
- **12 classes** disponibles
- **Stats principales** : Vitalité, Sagesse, Force, Intelligence, Chance, Agilité
- **PA/PM** : Points d'Action/Mouvement par tour
- **Niveaux 1-200** avec courbe XP exponentielle

#### 📋 Tâches détaillées (synchronisées avec Cursor)
- [ ] Système d’inscription/connexion sécurisé (JWT, validation forte)
- [ ] Gestion des sessions persistantes (reconnexion, expiration)
- [ ] Interface de sélection/création de personnage (client)
- [ ] Stockage et chargement des personnages (PostgreSQL)
- [ ] Validation côté client et serveur (anti-triche, cohérence)
- [ ] Modèle de personnage (stats, classe, niveau, expérience)
- [ ] Gain d’XP, montée de niveau, attribution de points
- [ ] Système de classes (guerrier, etc.) et compétences de base
- [ ] Interface de progression (client)

---

### **Phase 2 : Système d'Inventaire** 🎒
*Durée estimée : 2-3 semaines*

#### 🎯 Objectifs
- Inventaire avec slots
- Types d'objets (armes, armures, consommables)
- Équipement/déséquipement
- Persistence complète

#### 🎮 Mécaniques Dofus 1.29
- **60 slots** d'inventaire de base
- **8 slots d'équipement** : Casque, Cape, Amulette, Arme, Bouclier, Ceinture, Bottes, Anneau
- **Types d'objets** : Équipements, Consommables, Ressources, Quête
- **Restrictions** : Niveau, classe, alignement

#### 📋 Tâches détaillées (synchronisées avec Cursor)
- [ ] Gestion de l’inventaire (slots, types d’objets)
- [ ] Équipement/déséquipement d’objets
- [ ] Persistence inventaire en base de données
- [ ] Interface inventaire côté client

---

### **Phase 3 : Système de Combat Tour par Tour** ⚔️
*Durée estimée : 4-5 semaines*

#### 🎯 Objectifs
- Combat tactique case par case
- Initiative et ordre de jeu
- Dommages et résistances
- Interface de combat intuitive

#### 🎮 Mécaniques Dofus 1.29
- **Initiative** détermine l'ordre (Agilité + aléatoire)
- **PA/PM** limités par tour
- **Ligne de vue** pour sorts et attaques
- **Placement tactique** avant combat
- **4 éléments** : Terre, Feu, Air, Eau

#### 📋 Tâches détaillées (synchronisées avec Cursor)
- [ ] Détection d’engagement (proximité, clic, etc.)
- [ ] Gestion d’une instance de combat (séparation du monde principal)
- [ ] Tour par tour : initiative, file d’attente, timer
- [ ] Actions de base : déplacement, attaque, fin de tour
- [ ] Synchronisation des états de combat (client/serveur)
- [ ] Gestion des récompenses et sortie de combat
- [ ] UI de combat (ordre de tour, actions, logs)

---

### **Phase 4 : Système de Sorts** ✨
*Durée estimée : 3-4 semaines*

#### 🎯 Objectifs
- Sorts par classe avec niveaux
- Zones d'effet et portées
- Coûts en PA et conditions
- Effets et animations

#### 🎮 Mécaniques Dofus 1.29
- **Sorts de classe** uniques
- **6 niveaux** par sort
- **Zones d'effet** variées
- **Conditions** : Ligne de vue, état cible
- **Cooldowns** et limitations

#### 📋 Tâches détaillées (synchronisées avec Cursor)
- [ ] Implémentation des sorts par classe
- [ ] Gestion des niveaux de sorts
- [ ] Zones d’effet et portées
- [ ] Conditions d’utilisation (PA, ligne de vue, état)
- [ ] Effets et animations de sorts

---

### **Phase 5 : Système PNJ et Interactions** 🤖
*Durée estimée : 2-3 semaines*

#### 🎯 Objectifs
- PNJ avec dialogues
- Interactions contextuelles
- IA basique pour monstres
- Système de spawn

#### 🎮 Mécaniques Dofus 1.29
- **Monstres** avec groupes et familles
- **PNJ fonctionnels** (marchands, maîtres de sorts)
- **Dialogues** avec choix multiples
- **Spawn aléatoire** sur timer

#### 📋 Tâches détaillées (synchronisées avec Cursor)
- [ ] Implémentation des PNJ (dialogues, interactions)
- [ ] IA basique pour monstres
- [ ] Système de spawn de monstres
- [ ] Gestion des groupes/familles de monstres

---

### **Phase 6 : Système de Chat Multi-Canal** 💬
*Durée estimée : 1-2 semaines*

#### 🎯 Objectifs
- Chat général, guilde, privé
- Modération automatique
- Historique et filtres

#### 🎮 Mécaniques Dofus 1.29
- **Canaux** : Général, Guilde, Privé, Commerce, Recrutement
- **Commandes** : /w, /g, /c, etc.
- **Modération** anti-spam

#### 📋 Tâches détaillées (synchronisées avec Cursor)
- [ ] Système de chat global/local (WebSocket, filtrage)
- [ ] Gestion des canaux (général, privé, combat)
- [ ] Interface utilisateur de chat (client)
- [ ] Modération automatique et filtres

---

### **Phase 7 : Système Économique** 💰
*Durée estimée : 3-4 semaines*

#### 🎯 Objectifs
- Boutiques PNJ
- Échanges entre joueurs
- Monnaie (Kamas)
- Économie équilibrée

#### 🎮 Mécaniques Dofus 1.29
- **Kamas** comme monnaie unique
- **Boutiques** avec prix variables
- **Échanges** sécurisés entre joueurs
- **Taxes** sur transactions

#### 📋 Tâches détaillées (synchronisées avec Cursor)
- [ ] Implémentation des boutiques PNJ
- [ ] Système d’échange entre joueurs
- [ ] Gestion de la monnaie (Kamas)
- [ ] Système de taxes sur transactions

---

### **Phase 8 : Systèmes Avancés** 🏰
*Durée estimée : 4-6 semaines*

#### 🎯 Objectifs
- Guildes avec fonctionnalités
- Quêtes et missions
- Donjons de base
- Artisanat simple

#### 📋 Tâches détaillées (synchronisées avec Cursor)
- [ ] Système de guildes (création, gestion, chat)
- [ ] Implémentation de quêtes et missions
- [ ] Donjons de base (structure, accès, récompenses)
- [ ] Système d’artisanat simple

---

### **Phase 9 : Polish et Optimisation** ✨
*Durée estimée : 2-3 semaines*

#### 🎯 Objectifs
- Optimisation performance
- Stabilisation bugs
- Interface utilisateur
- Tests de charge

#### 📋 Tâches détaillées (synchronisées avec Cursor)
- [ ] Optimisation des performances serveur/client
- [ ] Correction des bugs critiques
- [ ] Amélioration de l’interface utilisateur
- [ ] Tests de charge et de montée en charge
- [ ] Monitoring (pprof, Prometheus, logs)
- [ ] Tests unitaires et d’intégration
- [ ] Documentation technique à jour
- [ ] Scripts de setup/dev (sans Docker)

---

## ⏱️ Timeline Globale

```
Phase 1: Personnages     │████████████│ (3-4 semaines)
Phase 2: Inventaire      │████████│     (2-3 semaines)  
Phase 3: Combat          │████████████████│ (4-5 semaines)
Phase 4: Sorts           │████████████│ (3-4 semaines)
Phase 5: PNJ             │████████│     (2-3 semaines)
Phase 6: Chat            │████│         (1-2 semaines)
Phase 7: Économie        │████████████│ (3-4 semaines)
Phase 8: Avancés         │████████████████████│ (4-6 semaines)
Phase 9: Polish          │████████│     (2-3 semaines)

TOTAL: 24-34 semaines (6-8 mois)
```

## 📊 Métriques de Réussite Alpha

### 🎯 **Fonctionnalités Obligatoires**
- ✅ **12 classes** jouables avec sorts uniques
- ✅ **Combat tour par tour** complet
- ✅ **Inventaire** et équipements fonctionnels
- ✅ **PNJ** et monstres interactifs
- ✅ **Chat** multi-canal
- ✅ **Économie** avec boutiques et échanges
- ✅ **3 donjons** minimum
- ✅ **Système de guildes** de base

### 🎯 **Performance Technique**
- ✅ **100+ joueurs** simultanés stables
- ✅ **Latence < 100ms** (95e percentile)
- ✅ **Uptime > 99%** sur 7 jours
- ✅ **0 bugs critiques** bloquants
- ✅ **Sauvegarde** automatique fiable

## 🎉 Livrable Alpha

À la fin de cette roadmap, Flumen aura :

### **🎮 Gameplay Complet**
- **Expérience Dofus 1.29** authentique
- **Toutes les mécaniques core** fonctionnelles
- **Progression** satisfaisante et équilibrée

### **🏗️ Architecture Scalable**
- **Base solide** pour fonctionnalités futures
- **Performance** optimisée pour 2500+ joueurs
- **Code maintenable** et documenté

### **👥 Communauté Ready**
- **Serveur stable** 24/7
- **Outils modération** intégrés
- **Support** multijoueur robuste

---

**🌊 Flumen Alpha - L'aventure épique commence ! ⚔️**

*Cette roadmap est un document vivant, ajusté selon les retours et priorités.*
