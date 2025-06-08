# setup-prerequisites-enhanced.ps1
# Production-grade prerequisite installer with advanced error recovery

#Requires -Version 7.0
#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:USERPROFILE\bushido-nft\logs\prerequisites.log",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipChocolatey,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# Import the framework module
$modulePath = Join-Path $PSScriptRoot "BushidoSetupFramework.psm1"

# If module doesn't exist, create it inline
if (-not (Test-Path $modulePath)) {
    # Create the module content inline
    $moduleContent = @'
# [Insert the BushidoSetupFramework.psm1 content from above here]
'@
    
    $moduleDir = Split-Path $modulePath -Parent
    if (-not (Test-Path $moduleDir)) {
        New-Item -ItemType Directory -Path $moduleDir -Force | Out-Null
    }
    
    Set-Content -Path $modulePath -Value $moduleContent -Encoding UTF8
}

# Import the module
Import-Module $modulePath -Force

# Create and run the orchestrator
try {
    $orchestrator = [BushidoSetupOrchestrator]::new()
    $orchestrator.Run()
}
catch {
    Write-Host "`n❌ Fatal error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    exit 1
}