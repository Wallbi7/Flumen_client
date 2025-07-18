# Script pour forcer le spawn de monstres sur la map 1,0
# Nécessite que le serveur soit démarré sur le port 9090

Write-Host "🌊 Flumen - Force Spawn Monsters" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Configuration
$SERVER_URL = "http://127.0.0.1:9090"
$MAP_ID = "map_1_0"

Write-Host "🎯 Cible: Map $MAP_ID" -ForegroundColor Yellow
Write-Host "🌐 Serveur: $SERVER_URL" -ForegroundColor Yellow
Write-Host ""

# 1. Vérifier si le serveur répond
Write-Host "🔍 Vérification du serveur..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/stats" -Method GET -TimeoutSec 5
    Write-Host "✅ Serveur accessible" -ForegroundColor Green
    Write-Host "📊 Stats actuelles: $($response.stats | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Serveur non accessible: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Assurez-vous que le serveur est démarré sur le port 9090" -ForegroundColor Yellow
    exit 1
}

# 2. Vérifier les monstres actuels sur la map
Write-Host ""
Write-Host "🔍 Vérification des monstres actuels sur $MAP_ID..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/map/$MAP_ID" -Method GET -TimeoutSec 5
    Write-Host "✅ Réponse reçue" -ForegroundColor Green
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
    Write-Host "❌ Erreur lors de la vérification: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Forcer le spawn de monstres
Write-Host ""
Write-Host "⚡ Forçage du spawn de monstres..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/spawn/$MAP_ID" -Method POST -TimeoutSec 5
    Write-Host "✅ Spawn forcé avec succès" -ForegroundColor Green
    Write-Host "📝 Message: $($response.message)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Erreur lors du spawn forcé: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Vérifier à nouveau les monstres
Write-Host ""
Write-Host "🔍 Vérification après spawn..." -ForegroundColor Green
Start-Sleep -Seconds 2  # Attendre un peu pour que le spawn soit traité

try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/map/$MAP_ID" -Method GET -TimeoutSec 5
    Write-Host "✅ Réponse reçue" -ForegroundColor Green
    Write-Host "📊 Monstres trouvés: $($response.count)" -ForegroundColor Gray
    
    if ($response.count -gt 0) {
        Write-Host "🎮 Monstres présents:" -ForegroundColor Cyan
        foreach ($monster in $response.monsters) {
            Write-Host "  - $($monster.template_id) (Niveau $($monster.level)) à ($($monster.pos_x), $($monster.pos_y))" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "🎉 Succès! Des monstres sont maintenant présents sur la map $MAP_ID" -ForegroundColor Green
        Write-Host "💡 Vous pouvez maintenant tester le combat dans le client Godot" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️ Aucun monstre n'a été spawné" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur lors de la vérification finale: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Script terminé" -ForegroundColor Cyan 