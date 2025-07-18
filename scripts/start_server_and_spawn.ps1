# Script pour démarrer le serveur et forcer le spawn de monstres
# Ce script démarre le serveur Go s'il n'est pas déjà en cours

Write-Host "🌊 Flumen - Start Server & Spawn Monsters" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Configuration
$SERVER_URL = "http://127.0.0.1:9090"
$MAP_ID = "map_1_0"
$SERVER_DIR = "..\..\Flumen_server"

Write-Host "🎯 Cible: Map $MAP_ID" -ForegroundColor Yellow
Write-Host "🌐 Serveur: $SERVER_URL" -ForegroundColor Yellow
Write-Host "📁 Dossier serveur: $SERVER_DIR" -ForegroundColor Yellow
Write-Host ""

# 1. Vérifier si le serveur est déjà en cours
Write-Host "🔍 Vérification du serveur..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/stats" -Method GET -TimeoutSec 3
    Write-Host "✅ Serveur déjà en cours sur le port 9090" -ForegroundColor Green
    $serverRunning = $true
} catch {
    Write-Host "⚠️ Serveur non accessible, démarrage en cours..." -ForegroundColor Yellow
    $serverRunning = $false
}

# 2. Démarrer le serveur si nécessaire
if (-not $serverRunning) {
    Write-Host "🚀 Démarrage du serveur..." -ForegroundColor Green
    
    # Vérifier si le dossier serveur existe
    if (-not (Test-Path $SERVER_DIR)) {
        Write-Host "❌ Dossier serveur non trouvé: $SERVER_DIR" -ForegroundColor Red
        Write-Host "💡 Assurez-vous que le dossier Flumen_server existe" -ForegroundColor Yellow
        exit 1
    }
    
    # Aller dans le dossier serveur
    Push-Location $SERVER_DIR
    
    try {
        # Démarrer le serveur en arrière-plan
        Write-Host "📦 Compilation et démarrage du serveur..." -ForegroundColor Green
        Start-Process -FilePath "go" -ArgumentList "run", "cmd/api/main.go" -WindowStyle Hidden
        
        # Attendre que le serveur démarre
        Write-Host "⏳ Attente du démarrage du serveur..." -ForegroundColor Yellow
        $maxAttempts = 30
        $attempt = 0
        
        while ($attempt -lt $maxAttempts) {
            try {
                $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/stats" -Method GET -TimeoutSec 2
                Write-Host "✅ Serveur démarré avec succès!" -ForegroundColor Green
                break
            } catch {
                $attempt++
                Write-Host "⏳ Tentative $attempt/$maxAttempts..." -ForegroundColor Gray
                Start-Sleep -Seconds 2
            }
        }
        
        if ($attempt -ge $maxAttempts) {
            Write-Host "❌ Le serveur n'a pas démarré dans le délai imparti" -ForegroundColor Red
            exit 1
        }
        
    } catch {
        Write-Host "❌ Erreur lors du démarrage du serveur: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    } finally {
        Pop-Location
    }
}

# 3. Attendre un peu pour que le système de spawn automatique s'initialise
Write-Host ""
Write-Host "⏳ Attente de l'initialisation du système de spawn..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 4. Vérifier les monstres actuels
Write-Host ""
Write-Host "🔍 Vérification des monstres actuels sur $MAP_ID..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/map/$MAP_ID" -Method GET -TimeoutSec 5
    Write-Host "📊 Monstres trouvés: $($response.count)" -ForegroundColor Gray
    
    if ($response.count -gt 0) {
        Write-Host "🎮 Monstres présents:" -ForegroundColor Cyan
        foreach ($monster in $response.monsters) {
            Write-Host "  - $($monster.template_id) (Niveau $($monster.level)) à ($($monster.pos_x), $($monster.pos_y))" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "🎉 Parfait! Des monstres sont déjà présents sur la map $MAP_ID" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Aucun monstre sur cette map, forçage du spawn..." -ForegroundColor Yellow
        
        # 5. Forcer le spawn de monstres
        Write-Host "⚡ Forçage du spawn de monstres..." -ForegroundColor Green
        try {
            $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/spawn/$MAP_ID" -Method POST -TimeoutSec 5
            Write-Host "✅ Spawn forcé avec succès" -ForegroundColor Green
            Write-Host "📝 Message: $($response.message)" -ForegroundColor Gray
            
            # 6. Vérifier à nouveau les monstres
            Write-Host ""
            Write-Host "🔍 Vérification après spawn..." -ForegroundColor Green
            Start-Sleep -Seconds 2
            
            $response = Invoke-RestMethod -Uri "$SERVER_URL/api/v1/monsters/map/$MAP_ID" -Method GET -TimeoutSec 5
            Write-Host "📊 Monstres trouvés: $($response.count)" -ForegroundColor Gray
            
            if ($response.count -gt 0) {
                Write-Host "🎮 Monstres présents:" -ForegroundColor Cyan
                foreach ($monster in $response.monsters) {
                    Write-Host "  - $($monster.template_id) (Niveau $($monster.level)) à ($($monster.pos_x), $($monster.pos_y))" -ForegroundColor Gray
                }
                Write-Host ""
                Write-Host "🎉 Succès! Des monstres sont maintenant présents sur la map $MAP_ID" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Aucun monstre n'a été spawné" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "❌ Erreur lors du spawn forcé: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ Erreur lors de la vérification: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "💡 Vous pouvez maintenant tester le combat dans le client Godot" -ForegroundColor Yellow
Write-Host "🏁 Script terminé" -ForegroundColor Cyan 