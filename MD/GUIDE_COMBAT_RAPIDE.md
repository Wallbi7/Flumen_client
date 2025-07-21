# 🎮 Guide de Test Combat Rapide - Flumen

## 🚀 Tests Disponibles

### **Touche T** - Test Combat Automatique
- Lance un combat de test avec terminaison automatique (10s)
- **Nouveau**: Grille de combat maintenant **VISIBLE** avec bordures grises
- Zones de placement colorées (cyan = alliés, orange = ennemis)
- Interface de combat complète

### **Touche M** - Diagnostic Monstres
- Affiche les monstres présents sur la map
- Vérifie les zones d'interaction
- Teste les propriétés de collision

### **Touche R** - Reset Complet
- Réinitialise complètement le système de combat
- Nettoie tous les états et variables
- Remet le jeu en mode normal

### **Touche Échap** - Arrêt Combat
- Termine immédiatement le combat en cours
- Masque l'interface et la grille
- Retour au mode exploration

### **Touche G** - DEBUG GRILLE ⭐ NOUVEAU
- **Force l'affichage** de la grille en rouge vif
- **Z-index maximum** pour être visible au-dessus de tout
- **Test ultime** pour vérifier la visibilité de la grille

### **Clic sur Monstre** - Combat Réel
- Déclenche un combat tactique complet
- **Nouveau**: Transition visuelle améliorée
- Grille 15x17 (255 cellules) bien visible
- Zones de placement automatiques

## 🎯 Améliorations Récentes

### ✅ **Visibilité de la Grille**
- **Bordures grises** sur toutes les cellules
- **Cellules légèrement transparentes** pour voir le fond
- **Couleurs renforcées** pour les états spéciaux
- **Centrage automatique** sur l'écran

### ✅ **Zones de Placement**
- **Côté gauche (cyan)**: Zone alliée (3 colonnes)
- **Côté droit (orange)**: Zone ennemie (3 colonnes)
- **Marquage visuel automatique** au démarrage

### ✅ **Transitions Visuelles**
- Grille **masquée** en mode exploration
- Grille **visible** pendant le combat
- **Nettoyage automatique** à la fin du combat

## 🧪 Procédure de Test

1. **Aller sur map_1_0** (5 monstres confirmés par le serveur)
2. **Appuyer sur T** pour voir la grille en action
3. **Observer la grille** : bordures grises + zones colorées
4. **Appuyer sur Échap** pour terminer
5. **Cliquer sur un monstre** pour combat réel
6. **Vérifier les transitions** visuelles

## 🔧 Diagnostic Visuel

Si la grille n'apparaît pas :
1. Vérifier les logs `[CombatGrid]`
2. Tester avec **Touche T** d'abord
3. **⭐ NOUVEAU : Touche G** pour debug rouge vif
4. Vérifier position avec `[CombatGrid] Grille centrée à:`
5. Utiliser **Touche R** pour reset complet

## 🚨 Test Debug Ultime (Touche G)

**Si grille invisible après combat lancé :**
1. **Appuyez sur G** → Grille forcée en ROUGE VIF
2. **Si grille rouge visible** → Problème de couleurs/opacité
3. **Si toujours rien** → Problème de position/z-index
4. **Logs attendus** : `[CombatGrid] 🔍 Debug appliqué`

## 📊 Spécifications Techniques

- **Grille**: 15x17 = 255 cellules
- **Cellules**: 86x43 pixels (format Dofus)
- **Bordures**: 1px gris (50% opacité)
- **Zones**: 3 colonnes de chaque côté
- **Centrage**: Automatique au centre écran

---
**🌊 Flumen - Combat Tactique Optimisé ! ⚔️** 