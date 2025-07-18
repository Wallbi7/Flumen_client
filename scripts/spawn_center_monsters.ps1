# Script pour forcer le spawn de monstres au centre de la map
Write-Host "🌊 Flumen - Spawn Monstres au Centre" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$SERVER_URL = "http://127.0.0.1:9090"
$MAP_ID = "map_1_0"

Write-Host "🎯 Forçage du spawn de monstres au centre de la map: $MAP_ID" -ForegroundColor Yellow
Write-Host ""

# 1. Vérifier les monstres actuels
Write-Host "📊 Vérification des monstres actuels..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/map/$MAP_ID" -Method GET -TimeoutSec 5
    Write-Host "Monstres actuels: $($response.count)" -ForegroundColor Gray
    
    if ($response.count -gt 0) {
        Write-Host "Positions actuelles:" -ForegroundColor Cyan
        foreach ($monster in $response.monsters) {
            Write-Host "  $($monster.template_id) à ($($monster.pos_x), $($monster.pos_y))" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Forcer le spawn de nouveaux monstres
Write-Host ""
Write-Host "⚡ Forçage du spawn de monstres au centre..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/spawn/$MAP_ID" -Method POST -TimeoutSec 5
    Write-Host "✅ Spawn forcé avec succès" -ForegroundColor Green
    Write-Host "📝 Message: $($response.message)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Erreur spawn forcé: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Vérifier les nouveaux monstres
Write-Host ""
Write-Host "🔍 Vérification des nouveaux monstres..." -ForegroundColor Green
Start-Sleep -Seconds 2

try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/map/$MAP_ID" -Method GET -TimeoutSec 5
    Write-Host "Monstres trouvés: $($response.count)" -ForegroundColor Gray
    
    if ($response.count -gt 0) {
        Write-Host "Positions des monstres (devraient être au centre):" -ForegroundColor Cyan
        foreach ($monster in $response.monsters) {
            $distanceFromCenter = [math]::Sqrt([math]::Pow($monster.pos_x - 960, 2) + [math]::Pow($monster.pos_y - 540, 2))
            Write-Host "  $($monster.template_id) à ($($monster.pos_x), $($monster.pos_y)) - Distance du centre: $([math]::Round($distanceFromCenter, 1))" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "🎉 Monstres spawnés au centre de la map!" -ForegroundColor Green
        Write-Host "💡 Rechargez la map dans Godot pour voir les nouveaux monstres" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️ Aucun monstre n'a été spawné" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur vérification: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Script terminé" -ForegroundColor Cyan 