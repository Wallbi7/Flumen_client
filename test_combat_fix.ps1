# Test du serveur Flumen
Write-Host "=== TEST DU SERVEUR FLUMEN ===" -ForegroundColor Green

# Test 1: Vérifier que le serveur répond
Write-Host "1. Test de connexion au serveur..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:9090/api/v1/classes" -Method GET -TimeoutSec 5
    Write-Host "✅ Serveur accessible (Code: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Serveur non accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Vérifier les classes disponibles
Write-Host "2. Test des classes disponibles..." -ForegroundColor Yellow
try {
    $classes = Invoke-WebRequest -Uri "http://127.0.0.1:9090/api/v1/classes" -Method GET
    $classesData = $classes.Content | ConvertFrom-Json
    Write-Host "✅ Classes trouvées: $($classesData.Count)" -ForegroundColor Green
    foreach ($class in $classesData) {
        Write-Host "   - $($class.name) ($($class.id))" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Erreur lors de la récupération des classes: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== INSTRUCTIONS POUR TESTER LE COMBAT ===" -ForegroundColor Green
Write-Host "1. Lancez Godot 4.4.1" -ForegroundColor Yellow
Write-Host "2. Ouvrez le projet Flumen_client" -ForegroundColor Yellow
Write-Host "3. Lancez la scène LoginScene.tscn" -ForegroundColor Yellow
Write-Host "4. Connectez-vous avec vos identifiants" -ForegroundColor Yellow
Write-Host "5. Sélectionnez un personnage" -ForegroundColor Yellow
Write-Host "6. Allez sur map_1_0 (clic droit vers la droite)" -ForegroundColor Yellow
Write-Host "7. Clic droit sur un monstre (tofu ou bouftou)" -ForegroundColor Yellow
Write-Host "8. Le combat devrait se lancer automatiquement" -ForegroundColor Yellow

Write-Host "`n=== LOGS À SURVEILLER ===" -ForegroundColor Green
Write-Host "Dans les logs du serveur, vous devriez voir:" -ForegroundColor Yellow
Write-Host "- 'Received initiate_combat request from [username]'" -ForegroundColor Cyan
Write-Host "- 'Player [username] wants to start combat with monster [type]'" -ForegroundColor Cyan
Write-Host "- 'Combat started successfully (ID: [uuid]) for player [username]'" -ForegroundColor Cyan

Write-Host "`n=== EN CAS DE PROBLÈME ===" -ForegroundColor Green
Write-Host "Si le combat ne se lance pas:" -ForegroundColor Yellow
Write-Host "1. Vérifiez les logs du serveur pour les erreurs" -ForegroundColor Cyan
Write-Host "2. Vérifiez que les monstres sont bien présents sur map_1_0" -ForegroundColor Cyan
Write-Host "3. Vérifiez que le client envoie bien 'monster_id': 'tofu' ou 'bouftou'" -ForegroundColor Cyan 