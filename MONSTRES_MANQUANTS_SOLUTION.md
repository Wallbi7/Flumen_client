# 🎮 Solution : Monstres manquants sur la map 1,0

## 🔍 Diagnostic du problème

Le problème vient du fait que le système de spawn automatique des monstres n'a pas encore généré de monstres sur la map 1,0. Voici comment résoudre cela :

## 🚀 Solution 1 : Spawn automatique (Recommandé)

Le serveur a un système de spawn automatique qui génère des monstres toutes les 30 secondes. Pour que les monstres apparaissent :

1. **Démarrez le serveur** :
   ```bash
   cd Flumen_server
   go run cmd/api/main.go
   ```

2. **Attendez 30-60 secondes** pour que le système de spawn automatique génère des monstres

3. **Rechargez la map** dans le client Godot

## ⚡ Solution 2 : Spawn forcé (Immédiat)

Si vous voulez des monstres immédiatement :

1. **Démarrez le serveur** (voir étape 1 ci-dessus)

2. **Exécutez le script de test** :
   ```powershell
   cd Flumen_client/scripts
   .\test_monsters.ps1
   ```

3. **Ou utilisez curl** :
   ```bash
   # Vérifier les monstres actuels
   curl http://127.0.0.1:9090/api/v1/monsters/map/map_1_0
   
   # Forcer le spawn
   curl -X POST http://127.0.0.1:9090/api/v1/monsters/spawn/map_1_0
   ```

## 🎯 Configuration des zones

La map 1,0 est configurée pour la zone "plains_astrub" qui peut spawner :
- **Tofus** (niveau 1) - 3 max, 70% chance de spawn
- **Bouftous** (niveau 1-2) - 2 max, 50% chance de spawn

## 🔧 Vérification

Pour vérifier que tout fonctionne :

1. **Vérifiez les stats du serveur** :
   ```bash
   curl http://127.0.0.1:9090/api/v1/monsters/stats
   ```

2. **Vérifiez les monstres sur la map** :
   ```bash
   curl http://127.0.0.1:9090/api/v1/monsters/map/map_1_0
   ```

## 🐛 Dépannage

### Serveur non accessible
- Vérifiez que le serveur est démarré sur le port 9090
- Vérifiez les logs du serveur pour des erreurs

### Aucun monstre après le spawn forcé
- Vérifiez que la base de données PostgreSQL est accessible
- Vérifiez les logs du serveur pour des erreurs de spawn

### Client ne voit pas les monstres
- Rechargez la map dans le client Godot
- Vérifiez que le client se connecte bien au serveur
- Vérifiez les logs du client pour des erreurs de chargement

## 📝 Logs utiles

Dans le serveur, cherchez ces logs :
- `"MonsterManager initialisé avec succès"`
- `"Monstre spawné"`
- `"Monstres récupérés pour la map"`

Dans le client Godot, cherchez ces logs :
- `"=== CHARGEMENT DES MONSTRES ==="`
- `"Monstres trouvés: X"`
- `"✅ Monstre créé"`

## 🎉 Résultat attendu

Une fois résolu, vous devriez voir :
- Des monstres (Tofus/Bouftous) sur la map 1,0
- Possibilité de cliquer droit sur les monstres pour initier un combat
- Système de combat fonctionnel avec désactivation du mouvement

---

**💡 Conseil** : Le spawn automatique est la solution la plus naturelle. Le spawn forcé est utile pour les tests de développement. 