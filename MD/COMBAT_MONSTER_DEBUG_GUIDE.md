# 🧪 **GUIDE DE TEST - Combat Monster Debug**

## 🎯 **Objectif**
Vérifier que les signaux monstres fonctionnent et que le combat se lance en cliquant sur un monstre.

## 🔧 **Modifications Appliquées**

### **✅ 1. Correction Signaux Monster**
- **Fichier** : `game/monsters/Monster.gd`
- **Fix** : Signaux déplacés en haut du fichier
- **Résultat** : Élimination des warnings "signal manquant"

### **✅ 2. Correction Détection Signaux**
- **Fichier** : `game/GameManager.gd` 
- **Fix** : `has_signal()` au lieu de `has_user_signal()`
- **Résultat** : Meilleure détection des signaux en Godot 4.x

### **✅ 3. Debug Complet**
- **Debug signaux** dans GameManager (liste tous les signaux disponibles)
- **Debug événements** dans Monster (détail des clics vs motion)
- **Test clavier** backup avec touche 'T'

## ⚙️ **ACTIVATION DU TEST (OPTIONNEL)**

### **Pour activer le test clavier 'T' :**
1. **Ouvrir** `main.tscn` dans Godot
2. **Clic droit** sur le noeud racine `Main`
3. **Attach Script** → **New Script**
4. **Copier-coller** le contenu de `game/combat/test_monster_clicks.gd`
5. **Sauvegarder**

**OU**

1. **Ajouter** un Node enfant à Main
2. **Attacher** le script `game/combat/test_monster_clicks.gd`

## 🧪 **Tests à Effectuer**

### **Test 1 : Lancer le Jeu**
1. **Démarrer** Flumen client
2. **Sélectionner** personnage
3. **Aller** sur map_1_0 (là où il y a des monstres)
4. **Regarder** les logs console

**✅ Résultat Attendu :**
```
[GameManager] 🔍 DEBUG - Signaux disponibles sur Monstre:
  - monster_clicked
  - monster_right_clicked  
  - monster_hovered
  - monster_died
[GameManager] ✅ Signal 'monster_clicked' connecté.
[GameManager] ✅ Signal 'monster_right_clicked' connecté.
```

### **Test 2 : Clic sur Monstre**
1. **Cliquer** (clic gauche) sur un monstre
2. **Observer** les logs console

**✅ Résultat Attendu :**
```
[Monster] 🖱️ ÉVÉNEMENT SOURIS sur Monstre - Bouton: 1 Pressed: true
[Monster] ✅ Clic détecté sur Monstre - Bouton: 1
[Monster] 🔥 Émission du signal monster_clicked pour: Monstre
[GameManager] ⚔️ Clic gauche sur monstre reçu pour lancer le combat: Monstre
[CombatManager] 🚀 Démarrage combat depuis serveur...
[CombatUI] 👁️ Interface de combat affichée
```

### **Test 3 : Test Clavier (Backup)**
1. **Appuyer** sur la touche `T` au clavier
2. **Observer** les logs console

**✅ Résultat Attendu :**
```
🧪 [MONSTER CLICK TEST] Test d'émission directe du signal monster_clicked sur: Monstre
✅ Signal monster_clicked trouvé - Émission...
[GameManager] ⚔️ Clic gauche sur monstre reçu pour lancer le combat: Monstre
```

## 🚨 **Si ça Ne Marche Pas**

### **❌ Toujours warnings "signal manquant"**
- Redémarrer Godot complètement
- Vérifier que `Monster.gd` est bien sauvegardé 
- Recompiler le projet

### **❌ Pas de clic détecté**
- Vérifier les logs pour `InputEventMouseButton`
- Essayer le test clavier `T`
- Vérifier qu'aucun autre élément UI n'absorbe les clics

### **❌ Signal émis mais pas de combat**
- Vérifier `_on_monster_clicked()` dans GameManager
- Vérifier `start_combat_with_monster()` existe
- Vérifier CombatManager initialisé

## 🎯 **Succès = Combat Lancé !**

**Si vous voyez :**
```
[CombatUI] 👁️ Interface de combat affichée
[CombatGrid] Grille affichée
```

**🎉 FÉLICITATIONS ! Le combat fonctionne !**

---

**Note** : Supprimer les scripts de test après validation si souhaité. 