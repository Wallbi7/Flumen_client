# Script simple pour tester l'API des monstres
# Assurez-vous que le serveur est démarré sur le port 9090

Write-Host "🌊 Flumen - Test Monsters API" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

$SERVER_URL = "http://127.0.0.1:9090"
$MAP_ID = "map_1_0"

Write-Host "🎯 Test de l'API des monstres pour la map: $MAP_ID" -ForegroundColor Yellow
Write-Host ""

# 1. Test de l'endpoint stats
Write-Host "📊 Test des stats du serveur..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/stats" -Method GET -TimeoutSec 5
    Write-Host "✅ Serveur accessible" -ForegroundColor Green
    Write-Host "📈 Stats: $($response.stats | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Serveur non accessible: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Assurez-vous que le serveur est démarré: go run cmd/api/main.go" -ForegroundColor Yellow
    exit 1
}

# 2. Test de l'endpoint monstres sur la map
Write-Host ""
Write-Host "🎮 Test des monstres sur la map..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/map/$MAP_ID" -Method GET -TimeoutSec 5
    Write-Host "✅ API accessible" -ForegroundColor Green
    Write-Host "📊 Monstres trouvés: $($response.count)" -ForegroundColor Gray
    
    if ($response.count -gt 0) {
        Write-Host "🎮 Monstres présents:" -ForegroundColor Cyan
        foreach ($monster in $response.monsters) {
            Write-Host "  - $($monster.template_id) (Niveau $($monster.level)) à ($($monster.pos_x), $($monster.pos_y))" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️ Aucun monstre sur cette map" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur API: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Test du spawn forcé
Write-Host ""
Write-Host "⚡ Test du spawn forcé..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/spawn/$MAP_ID" -Method POST -TimeoutSec 5
    Write-Host "✅ Spawn forcé réussi" -ForegroundColor Green
    Write-Host "📝 Message: $($response.message)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Erreur spawn forcé: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Vérification finale
Write-Host ""
Write-Host "🔍 Vérification finale..." -ForegroundColor Green
Start-Sleep -Seconds 2

try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/map/$MAP_ID" -Method GET -TimeoutSec 5
    Write-Host "📊 Monstres trouvés: $($response.count)" -ForegroundColor Gray
    
    if ($response.count -gt 0) {
        Write-Host "🎮 Monstres présents:" -ForegroundColor Cyan
        foreach ($monster in $response.monsters) {
            Write-Host "  - $($monster.template_id) (Niveau $($monster.level)) à ($($monster.pos_x), $($monster.pos_y))" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "🎉 Succès! Des monstres sont présents sur la map $MAP_ID" -ForegroundColor Green
        Write-Host "💡 Vous pouvez maintenant tester le combat dans le client Godot" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️ Aucun monstre n'a été spawné" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur vérification finale: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Test terminé" -ForegroundColor Cyan 