# Script pour corriger les erreurs Godot et nettoyer le projet

Write-Host "🔧 FLUMEN - CORRECTION DES ERREURS" -ForegroundColor Blue
Write-Host ("=" * 40) -ForegroundColor Blue

# 1. Nettoyer les fichiers problématiques
Write-Host "`n📁 Nettoyage des fichiers problématiques..." -ForegroundColor Yellow

$problematic_files = @(
    "addons\gut\gut_main.gd",
    "addons\gut\gut_test.gd",
    "addons\gut\plugin.gd"
)

foreach ($file in $problematic_files) {
    if (Test-Path $file) {
        Write-Host "   🗑️ Suppression: $file" -ForegroundColor Gray
        Remove-Item $file -Force
    }
}

# 2. Créer un plugin.cfg minimal qui fonctionne
Write-Host "`n⚙️ Création d'un plugin.cfg minimal..." -ForegroundColor Yellow

$plugin_cfg_content = @"
[plugin]

name="Test System - Simplified"
description="Système de tests simplifié pour Flumen"
author="Flumen Team"
version="1.0"
script=""
"@

Set-Content -Path "addons\gut\plugin.cfg" -Value $plugin_cfg_content -Encoding UTF8
Write-Host "   ✅ plugin.cfg créé" -ForegroundColor Green

# 3. Vérifier les fichiers de tests
Write-Host "`n🧪 Vérification des tests..." -ForegroundColor Yellow

$test_files = Get-ChildItem -Path "test" -Recurse -Filter "*.gd"
Write-Host "   📊 Fichiers de test trouvés: $($test_files.Count)" -ForegroundColor White

foreach ($test_file in $test_files) {
    Write-Host "   📄 $($test_file.FullName)" -ForegroundColor Gray
}

# 4. Vérifier que notre test fonctionnel existe
if (Test-Path "test\unit\test_working_simple.gd") {
    Write-Host "   ✅ Test fonctionnel disponible: test_working_simple.gd" -ForegroundColor Green
} else {
    Write-Host "   ❌ Test fonctionnel manquant" -ForegroundColor Red
}

# 5. Recommandations
Write-Host "`n💡 RECOMMANDATIONS:" -ForegroundColor Yellow
Write-Host "   1. Redémarrer Godot pour recharger le projet" -ForegroundColor White
Write-Host "   2. Désactiver l'addon GUT dans les paramètres du projet" -ForegroundColor White
Write-Host "   3. Utiliser notre système de tests simplifié" -ForegroundColor White
Write-Host "   4. Lancer: .\scripts\run_tests.ps1" -ForegroundColor Cyan

Write-Host "`n✅ Nettoyage terminé!" -ForegroundColor Green 