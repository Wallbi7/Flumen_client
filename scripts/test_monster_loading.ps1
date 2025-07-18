# Script pour tester le chargement des monstres et voir la structure des données
# Ce script vérifie l'API et affiche la structure complète des données

Write-Host "🌊 Flumen - Test Monster Loading" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

$SERVER_URL = "http://127.0.0.1:9090"
$MAP_ID = "map_1_0"

Write-Host "🎯 Test du chargement des monstres pour: $MAP_ID" -ForegroundColor Yellow
Write-Host ""

# 1. Test de l'endpoint monstres avec affichage détaillé
Write-Host "📊 Récupération des monstres avec structure détaillée..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/map/$MAP_ID" -Method GET -TimeoutSec 5
    Write-Host "✅ API accessible" -ForegroundColor Green
    Write-Host "📊 Monstres trouvés: $($response.count)" -ForegroundColor Gray
    
    if ($response.count -gt 0) {
        Write-Host "🎮 Structure des monstres:" -ForegroundColor Cyan
        foreach ($monster in $response.monsters) {
            Write-Host "  === MONSTRE ===" -ForegroundColor Yellow
            Write-Host "  ID: $($monster.id)" -ForegroundColor Gray
            Write-Host "  Template ID: $($monster.template_id)" -ForegroundColor Gray
            Write-Host "  Map ID: $($monster.map_id)" -ForegroundColor Gray
            Write-Host "  Position: ($($monster.pos_x), $($monster.pos_y))" -ForegroundColor Gray
            Write-Host "  Niveau: $($monster.level)" -ForegroundColor Gray
            Write-Host "  Vivant: $($monster.is_alive)" -ForegroundColor Gray
            Write-Host "  Comportement: $($monster.behavior)" -ForegroundColor Gray
            
            Write-Host "  Stats:" -ForegroundColor Gray
            $stats = $monster.stats
            Write-Host "    Vie: $($stats.health)/$($stats.max_health)" -ForegroundColor Gray
            Write-Host "    Mana: $($stats.mana)/$($stats.max_mana)" -ForegroundColor Gray
            Write-Host "    PA: $($stats.action_points)/$($stats.max_action_points)" -ForegroundColor Gray
            Write-Host "    PM: $($stats.movement_points)/$($stats.max_movement_points)" -ForegroundColor Gray
            Write-Host "    Force: $($stats.strength)" -ForegroundColor Gray
            Write-Host "    Intelligence: $($stats.intelligence)" -ForegroundColor Gray
            Write-Host "    Agilité: $($stats.agility)" -ForegroundColor Gray
            Write-Host "    Vitalité: $($stats.vitality)" -ForegroundColor Gray
            Write-Host "    Sagesse: $($stats.wisdom)" -ForegroundColor Gray
            Write-Host "    Chance: $($stats.chance)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "⚠️ Aucun monstre sur cette map" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur API: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Test de l'endpoint stats pour voir l'état global
Write-Host ""
Write-Host "📈 Stats globales du serveur..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/stats" -Method GET -TimeoutSec 5
    Write-Host "✅ Stats récupérées" -ForegroundColor Green
    Write-Host "📊 Stats détaillées:" -ForegroundColor Gray
    $stats = $response.stats
    Write-Host "  Total monstres: $($stats.total_monsters)" -ForegroundColor Gray
    Write-Host "  Monstres vivants: $($stats.alive_monsters)" -ForegroundColor Gray
    Write-Host "  Zones gérées: $($stats.managed_zones)" -ForegroundColor Gray
    Write-Host "  Maps gérées: $($stats.managed_maps)" -ForegroundColor Gray
    
    Write-Host "  Monstres par map:" -ForegroundColor Gray
    $monstersByMap = $stats.monsters_by_map
    foreach ($map in $monstersByMap.Keys) {
        Write-Host "    $map : $($monstersByMap[$map]) monstres" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Erreur stats: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Test terminé" -ForegroundColor Cyan 