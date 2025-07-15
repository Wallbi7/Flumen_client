# Script pour configurer les hooks Git pour Flumen MMORPG
param(
    [switch]$Force = $false
)

$ProjectPath = Split-Path -Parent $PSScriptRoot
$GitHooksPath = Join-Path $ProjectPath ".git\hooks"
$CustomHooksPath = Join-Path $ProjectPath ".githooks"

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Test-GitRepository {
    if (-not (Test-Path (Join-Path $ProjectPath ".git"))) {
        Write-ColorText "❌ Ce n'est pas un repository Git!" "Red"
        return $false
    }
    return $true
}

function Install-GitHooks {
    Write-ColorText "🔧 Installation des hooks Git..." "Blue"
    
    if (-not (Test-Path $GitHooksPath)) {
        New-Item -ItemType Directory -Path $GitHooksPath -Force | Out-Null
    }
    
    $PreCommitSource = Join-Path $CustomHooksPath "pre-commit"
    $PreCommitDest = Join-Path $GitHooksPath "pre-commit"
    
    if (Test-Path $PreCommitSource) {
        if ((Test-Path $PreCommitDest) -and -not $Force) {
            Write-ColorText "⚠️ Le hook pre-commit existe déjà. Utilisez -Force pour le remplacer." "Yellow"
            return $false
        }
        
        Copy-Item $PreCommitSource $PreCommitDest -Force
        Write-ColorText "✅ Hook pre-commit installé" "Green"
        return $true
    } else {
        Write-ColorText "❌ Fichier hook pre-commit non trouvé: $PreCommitSource" "Red"
        return $false
    }
}

# MAIN SCRIPT
Write-ColorText "🎮 FLUMEN MMORPG - CONFIGURATION HOOKS GIT" "Blue"
Write-ColorText "===========================================" "Blue"

if (-not (Test-GitRepository)) {
    exit 1
}

if (Install-GitHooks) {
    Write-ColorText "`n🎉 Hooks Git installés avec succès!" "Green"
} else {
    Write-ColorText "`n❌ Échec de l'installation des hooks" "Red"
    exit 1
}
