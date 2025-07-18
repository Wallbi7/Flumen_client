# Test rapide de l'API des monstres
Write-Host "Test API monstres..." -ForegroundColor Green

try {
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:9090/api/v1/monsters/map/map_1_0" -Method GET
    Write-Host "Monstres trouvés: $($response.count)" -ForegroundColor Yellow
    
    if ($response.count -gt 0) {
        Write-Host "Premier monstre:" -ForegroundColor Cyan
        $monster = $response.monsters[0]
        Write-Host "  Template ID: $($monster.template_id)" -ForegroundColor Gray
        Write-Host "  Position: ($($monster.pos_x), $($monster.pos_y))" -ForegroundColor Gray
        Write-Host "  Niveau: $($monster.level)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
} 