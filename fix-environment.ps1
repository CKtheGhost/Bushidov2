# fix-environment.ps1
# Quick fix for the refreshenv issue

function Update-EnvironmentVariables {
    $machineEnv = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
    $userEnv = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    $env:Path = "$machineEnv;$userEnv"
    
    # Import Chocolatey PowerShell module if available
    $chocoModule = "$env:ProgramData\chocolatey\helpers\chocolateyProfile.psm1"
    if (Test-Path $chocoModule) {
        Import-Module $chocoModule
        Update-SessionEnvironment
    }
}

# Fix the immediate issue
Update-EnvironmentVariables

# Verify installations
Write-Host "`n🔍 Checking installed tools..." -ForegroundColor Cyan
@("node", "npm", "pnpm", "git", "choco") | ForEach-Object {
    if (Get-Command $_ -ErrorAction SilentlyContinue) {
        Write-Host "✅ $_ is available" -ForegroundColor Green
    } else {
        Write-Host "❌ $_ is NOT available" -ForegroundColor Red
    }
}

Write-Host "`n💡 If pnpm is missing, install it with:" -ForegroundColor Yellow
Write-Host "   npm install -g pnpm" -ForegroundColor White