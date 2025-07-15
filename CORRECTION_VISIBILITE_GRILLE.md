# 🔧 Correction Visibilité Grille de Combat

## 🚨 Problème Identifié

D'après vos logs VAN MODE, le système de combat fonctionne techniquement mais la **grille reste invisible** :

```
[CombatManager] 🗺️ Grille de combat affichée
[CombatManager] ✅ Zones de placement définies: 51 alliées, 51 ennemies
```

Le système rapporte que la grille est affichée, mais elle n'est pas visible à l'écran.

## ✅ Corrections Appliquées

### 1. **Amélioration de l'Opacité**

**Avant :**
```gdscript
visual.color = Color(1.0, 1.0, 1.0, 0.1)  # 10% opacité
top_line.color = Color(0.5, 0.5, 0.5, 0.8)  # Gris foncé
```

**Après :**
```gdscript
visual.color = Color(1.0, 1.0, 1.0, 0.3)  # 30% opacité
top_line.color = Color(0.8, 0.8, 0.8, 1.0)  # Gris clair, 100% opacité
```

### 2. **Couleurs Plus Vives**

**Zones de placement améliorées :**
```gdscript
CellState.PLACEMENT_ALLY:
    return Color(0.0, 1.0, 1.0, 0.9)  # Cyan vif (90% opacité)
CellState.PLACEMENT_ENEMY:
    return Color(1.0, 0.5, 0.0, 0.9)  # Orange vif (90% opacité)
```

### 3. **Fonction Debug Ultime**

**Nouveau raccourci clavier G :**
```gdscript
func force_visible_debug():
    visible = true
    z_index = 1000  # Au-dessus de tout
    # Colorer toutes les cellules en ROUGE VIF
    visual.color = Color.RED * 0.8
```

## 🎮 Tests à Effectuer

### **Test 1 : Combat Normal**
1. Appuyez sur **T** (test combat)
2. Cherchez des **bordures grises** plus visibles
3. Observez les **zones colorées** (cyan/orange)

### **Test 2 : Debug Ultime**
1. Lancez un combat (T ou clic monstre)
2. Appuyez sur **G** (debug grille)
3. **Grille ROUGE VIF** devrait apparaître
4. Si visible → Problème résolu
5. Si invisible → Problème de position

## 🔍 Diagnostic Attendu

### **Si grille maintenant visible :**
✅ **Problème résolu** - Opacité était trop faible

### **Si grille rouge (G) visible mais pas normale :**
✅ **Grille fonctionne** - Ajuster couleurs normales

### **Si rien n'est visible même en rouge :**
❌ **Problème de position/z-index** - Investigation plus poussée

## 📊 Spécifications Mises à Jour

- **Fond cellules** : 30% opacité (au lieu de 10%)
- **Bordures** : Gris clair 100% opacité (au lieu de 80%)
- **Zones alliées** : Cyan vif 90% opacité
- **Zones ennemies** : Orange vif 90% opacité
- **Debug mode** : Rouge vif, z-index 1000

## 🚀 Commandes de Test

| Touche | Action | Résultat Attendu |
|--------|--------|------------------|
| **T** | Test combat | Grille visible avec bordures grises |
| **G** | Debug grille | Grille ROUGE VIF ultra-visible |
| **M** | Diagnostic monstres | Infos interactions |
| **R** | Reset complet | Nettoyage système |
| **Échap** | Arrêt combat | Retour mode normal |

## 🔄 Prochaines Étapes

1. **Testez maintenant** avec les touches T puis G
2. **Rapportez** ce que vous observez
3. **Si toujours invisible** → Investigation z-index/position
4. **Si visible** → Ajustement final des couleurs

---

**🎯 Test immédiat : T → G → Observez !** 