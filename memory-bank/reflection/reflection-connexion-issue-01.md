# 🧠 Réflexion - Résolution Problème de Connexion (Tâche #XXX)

## 📌 Contexte de la Tâche
- **Objectif :** Résoudre une erreur "401 Unauthorized" persistante qui bloquait le développement.
- **État Initial :** Le client Godot ne pouvait pas récupérer la liste des personnages, et les logs serveur étaient vides, rendant le diagnostic difficile.

## 🔑 Apprentissages et Points Clés

1.  **Importance des Logs Explicites :** Le premier obstacle était le manque de logs dans le middleware JWT du serveur. Sans logs pour confirmer la réception (ou non) de la requête et du token, nous étions aveugles. L'ajout de logs a été le catalyseur de la résolution.
    - **Leçon :** Ne jamais faire confiance à un middleware "silencieux". Toujours logger les entrées, les décisions clés et les sorties.

2.  **La Source de Vérité est le Build :** Plusieurs corrections dans le code source Go ne prenaient pas effet car le serveur était lancé depuis un exécutable (`api.exe`) qui n'avait pas été recompilé.
    - **Leçon :** Toujours avoir un processus de build (`go build`) clair et l'exécuter après chaque modification. Ne pas supposer que `go run` est suffisant en permanence, surtout quand des launchers sont impliqués.

3.  **Incohérences de Types de Données :** L'erreur la plus subtile était le conflit de type entre la base de données (UUID pour `character_id`) et le code Go (qui attendait un `uint`). Cela a causé une erreur `500 Internal Server Error` difficile à tracer car elle survenait *après* le middleware d'authentification.
    - **Leçon :** Assurer une cohérence parfaite des modèles de données (`structs` Go) avec le schéma de la base de données. Une seule différence peut faire tomber toute la chaîne de traitement.

4.  **Robustesse du Client :** Le client doit être capable de gérer les échecs d'authentification gracieusement. La solution finale, qui consiste à détecter une réponse `401` et à forcer une déconnexion (suppression du token local + redirection), est une pratique essentielle pour une bonne expérience utilisateur.
    - **Leçon :** Ne pas assumer qu'un token stocké localement est toujours valide. Toujours avoir un plan de secours en cas d'échec de validation.

## 🛠️ Améliorations au Workflow

- **Checklist de Débogage Serveur :**
    1. Les logs sont-ils activés et suffisamment détaillés ?
    2. Le serveur a-t-il été recompilé (`go build`) ?
    3. Les modèles de données Go correspondent-ils au schéma de la base de données ?
    4. Les clés de contexte (pour passer des données entre middlewares) sont-elles cohérentes ?

- **Checklist de Débogage Client :**
    1. L'URL du serveur est-elle correcte ?
    2. L'en-tête `Authorization` est-il correctement formaté ?
    3. Comment le client réagit-il à un code d'erreur (401, 403, 500) ? Est-ce qu'il informe l'utilisateur ou boucle à l'infini ?

## ✅ Conclusion
Cette tâche a été bien plus qu'une simple correction de bug. Elle a permis de renforcer les fondations du projet en améliorant les logs, en solidifiant le processus de build et en assurant la cohérence des données, rendant le système global plus fiable et plus facile à déboguer à l'avenir. 