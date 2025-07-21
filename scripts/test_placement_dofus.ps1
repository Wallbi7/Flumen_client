# Script PowerShell pour tester le système de placement style Dofus
# Flumen MMORPG - Système de Combat

Write-Host "=== TEST PLACEMENT STYLE DOFUS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎮 Lancement du client Godot avec le système de placement..." -ForegroundColor Green

# Chemin vers Godot et le projet
$GodotPath = "C:\Users\Abdullah\Flumen\Godot_v4.4.1-stable_win64.exe"
$ProjectPath = "C:\Users\Abdullah\Flumen\Flumen_client"
$TestScene = "res://TestPlacementScene.tscn"

# Vérification des prérequis
if (-not (Test-Path $GodotPath)) {
    Write-Host "❌ Erreur: Godot non trouvé à $GodotPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ProjectPath)) {
    Write-Host "❌ Erreur: Projet non trouvé à $ProjectPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Godot trouvé: $GodotPath" -ForegroundColor Green
Write-Host "✅ Projet trouvé: $ProjectPath" -ForegroundColor Green
Write-Host ""

Write-Host "🚀 Lancement de la scène de test..." -ForegroundColor Yellow
Write-Host ""
Write-Host "INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host "  - Une fois Godot ouvert, appuyez sur ESPACE pour démarrer le test" -ForegroundColor White
Write-Host "  - Vous verrez une grille isométrique 17x15" -ForegroundColor White
Write-Host "  - Zones bleues = placement allié (côté gauche)" -ForegroundColor Blue
Write-Host "  - Zones rouges = placement ennemi (côté droit)" -ForegroundColor Red
Write-Host "  - Cliquez sur une zone bleue pour placer votre personnage" -ForegroundColor White
Write-Host "  - Le système reproduit fidèlement Dofus!" -ForegroundColor Green
Write-Host ""

# Lancement de Godot
try {
    & $GodotPath --path $ProjectPath --scene $TestScene
    Write-Host "✅ Test terminé" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du lancement: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}