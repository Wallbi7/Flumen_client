#!/usr/bin/env pwsh

# Script de démonstration des tests de bugs Flumen MMORPG
param(
    [switch]$Verbose = $false,
    [switch]$ShowDetails = $false
)

$ErrorActionPreference = "Stop"

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-ColorText ("=" * 60) "Cyan"
    Write-ColorText "🎮 $Title" "Yellow"
    Write-ColorText ("=" * 60) "Cyan"
}

function Write-Section {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-ColorText ("🔍 $Title") "Green"
    Write-ColorText ("-" * 40) "DarkGray"
}

function Show-BugTestsDemo {
    Write-Header "FLUMEN MMORPG - DÉMONSTRATION DES TESTS DE BUGS"
    
    Write-ColorText "`n📋 Cette démonstration montre comment les tests préviennent les régressions" "White"
    Write-ColorText "   basés sur les bugs réels rencontrés pendant le développement.`n" "White"
    
    if ($ShowDetails) {
        Show-BugCategories
    }
    
    Write-Section "Exécution des tests de bugs"
    
    $startTime = Get-Date
    
    try {
        Write-ColorText "🚀 Lancement des tests..." "Yellow"
        
        $godotPath = Get-GodotPath
        if (-not $godotPath) {
            throw "Godot non trouvé"
        }
        
        Write-ColorText "✅ Godot trouvé: $godotPath" "Green"
        
        $result = & $godotPath --headless --script "scripts/test_runner_simple.gd" 2>&1
        $exitCode = $LASTEXITCODE
        
        $duration = (Get-Date) - $startTime
        
        Write-Section "Résultats de l'exécution"
        
        if ($Verbose) {
            Write-ColorText "📝 Sortie complète des tests:" "DarkGray"
            Write-Host $result
        }
        
        Show-TestResults $duration $exitCode
        
        if ($ShowDetails) {
            Show-BugPreventionValue
        }
        
    } catch {
        Write-ColorText "❌ Erreur lors de l'exécution: $($_.Exception.Message)" "Red"
        exit 1
    }
}

function Show-BugCategories {
    Write-Section "Catégories de bugs testées"
    
    Write-ColorText "  🌐 WebSocket Bugs" "Cyan"
    Write-ColorText "    └─ Connexion, messages, timeout, reconnexion" "DarkGray"
    Write-ColorText "  🗺️ Map Transition Bugs" "Cyan"  
    Write-ColorText "    └─ Coordonnées négatives, directions, spawn positions" "DarkGray"
    Write-ColorText "  🚨 Critical Bugs" "Cyan"
    Write-ColorText "    └─ Division par zéro, timeout auth, coordonnées extrêmes" "DarkGray"
    Write-ColorText "  📚 Basic Tests" "Cyan"
    Write-ColorText "    └─ Tests de base pour validation du système" "DarkGray"
}

function Get-GodotPath {
    $possiblePaths = @(
        "C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe",
        "C:\Godot\Godot_v4.4.1-stable_win64.exe",
        "godot"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path -ErrorAction SilentlyContinue) {
            return $path
        }
    }
    
    return $null
}

function Show-TestResults {
    param($Duration, $ExitCode)
    
    Write-ColorText "⏱️ Durée: $($Duration.TotalSeconds.ToString('F2')) secondes" "DarkGray"
    Write-ColorText "🎯 Code de sortie: $ExitCode" "DarkGray"
    
    Write-Host "`n"
    
    if ($ExitCode -eq 0) {
        Write-ColorText "🎉 TOUS LES TESTS ONT RÉUSSI!" "Green"
        Write-ColorText "   Le système Flumen est protégé contre les régressions!" "Green"
    } else {
        Write-ColorText "⚠️ CERTAINS TESTS ONT ÉCHOUÉ!" "Red"
        Write-ColorText "   Des régressions ont été détectées!" "Red"
    }
}

function Show-BugPreventionValue {
    Write-Section "Valeur de la prévention des bugs"
    
    Write-ColorText "💡 Ces tests préviennent les régressions suivantes:" "Yellow"
    
    $preventedBugs = @(
        "🔗 GameManager ne trouve plus WebSocketManager",
        "📨 Messages WebSocket mal formatés qui plantent le serveur",
        "⏱️ Timeouts non gérés causant des blocages",
        "🗺️ Coordonnées négatives générant des erreurs",
        "🧭 Calculs de direction incorrects dans les transitions",
        "📍 Positions de spawn hors limites",
        "➗ Divisions par zéro dans les outils de debug",
        "🔐 Timeouts d'authentification non détectés",
        "🌐 Coordonnées extrêmes causant des overflows"
    )
    
    foreach ($bug in $preventedBugs) {
        Write-ColorText "  ✓ $bug" "Green"
    }
    
    Write-Host "`n"
    Write-ColorText "🚀 Recommandations:" "Yellow"
    Write-ColorText "  • Lancez ces tests avant chaque commit" "White"
    Write-ColorText "  • Ajoutez un test pour chaque nouveau bug découvert" "White"
    Write-ColorText "  • Intégrez les tests dans votre pipeline CI/CD" "White"
    Write-ColorText "  • Examinez les échecs pour identifier les régressions" "White"
}

if ($args.Count -eq 0 -or $args[0] -eq "--help" -or $args[0] -eq "-h") {
    Write-Header "AIDE - Tests de bugs Flumen MMORPG"
    Write-Host @"

USAGE:
    .\scripts\demo_bug_tests.ps1 [OPTIONS]

OPTIONS:
    -Verbose        Affiche la sortie complète des tests
    -ShowDetails    Affiche les détails des catégories et recommandations
    -h, --help      Affiche cette aide

EXEMPLES:
    .\scripts\demo_bug_tests.ps1
    .\scripts\demo_bug_tests.ps1 -Verbose
    .\scripts\demo_bug_tests.ps1 -ShowDetails

"@
    exit 0
}

Show-BugTestsDemo
