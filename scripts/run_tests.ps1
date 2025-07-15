# Script PowerShell pour lancer les tests Flumen avec Godot CLI + GUT
param(
    [string]$TestDir = "res://test/",
    [string]$GodotPath = "C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe",
    [switch]$Verbose = $false,
    [switch]$ExitOnFail = $true
)

# Configuration
$ProjectPath = Split-Path -Parent $PSScriptRoot
$TestResultsDir = Join-Path $ProjectPath "test_results"
$LogFile = Join-Path $TestResultsDir "test_log.txt"

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Test-GodotInstallation {
    Write-ColorText "🔍 Vérification de l'installation Godot..." "Blue"
    
    if (-not (Test-Path $GodotPath)) {
        Write-ColorText "❌ Godot non trouvé à: $GodotPath" "Red"
        Write-ColorText "💡 Veuillez installer Godot 4.4.1 ou modifier le chemin" "Yellow"
        return $false
    }
    
    Write-ColorText "✅ Godot trouvé: $GodotPath" "Green"
    return $true
}

function Initialize-TestEnvironment {
    Write-ColorText "🏗️ Initialisation de l'environnement de test..." "Blue"
    
    if (-not (Test-Path $TestResultsDir)) {
        New-Item -ItemType Directory -Path $TestResultsDir -Force | Out-Null
    }
    
    if (Test-Path $LogFile) {
        Remove-Item $LogFile -Force
    }
    
    Write-ColorText "✅ Environnement de test initialisé" "Green"
}

function Run-GodotTests {
    param([string]$TestDirectory)
    
    Write-ColorText "🚀 Lancement des tests Godot..." "Blue"
    Write-ColorText "📁 Répertoire de test: $TestDirectory" "Blue"
    
    $GodotArgs = @(
        "--headless",
        "--path", $ProjectPath,
        "--script", "res://scripts/test_runner_simple.gd",
        "--", 
        "--test-dir", $TestDirectory
    )
    
    if ($Verbose) {
        Write-ColorText "🔧 Arguments Godot: $($GodotArgs -join ' ')" "Yellow"
        $GodotArgs += "--verbose"
    }
    
    $StartTime = Get-Date
    
    try {
        $Process = Start-Process -FilePath $GodotPath -ArgumentList $GodotArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput $LogFile
        
        $EndTime = Get-Date
        $Duration = $EndTime - $StartTime
        
        Write-ColorText "⏱️ Durée des tests: $($Duration.TotalSeconds.ToString('F2')) secondes" "Blue"
        
        return $Process.ExitCode
    }
    catch {
        Write-ColorText "❌ Erreur lors du lancement des tests: $($_.Exception.Message)" "Red"
        return 1
    }
}

function Show-TestResults {
    param([int]$ExitCode)
    
    Write-ColorText "`n📊 RÉSULTATS DES TESTS" "Blue"
    Write-ColorText ("=" * 50) "Blue"
    
    if (Test-Path $LogFile) {
        $LogContent = Get-Content $LogFile -Raw
        Write-Host $LogContent
    }
    
    if ($ExitCode -eq 0) {
        Write-ColorText "`n✅ TOUS LES TESTS ONT RÉUSSI!" "Green"
    } else {
        Write-ColorText "`n❌ CERTAINS TESTS ONT ÉCHOUÉ!" "Red"
    }
    
    Write-ColorText ("=" * 50) "Blue"
}

# MAIN SCRIPT
Write-ColorText "🎮 FLUMEN MMORPG - TEST RUNNER" "Blue"
Write-ColorText ("=" * 32) "Blue"

if (-not (Test-GodotInstallation)) {
    exit 1
}

Initialize-TestEnvironment
$ExitCode = Run-GodotTests -TestDirectory $TestDir
Show-TestResults -ExitCode $ExitCode

if ($ExitOnFail -and $ExitCode -ne 0) {
    Write-ColorText "`n🚨 Tests échoués - Arrêt avec code d'erreur" "Red"
    exit $ExitCode
}

Write-ColorText "`n🎯 Tests terminés avec succès!" "Green"
