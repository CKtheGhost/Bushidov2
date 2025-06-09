# Run-Bushido-Setup.ps1
# Simple runner script for Bushido NFT project setup

Write-Host "`n🏯 Bushido NFT Setup Runner" -ForegroundColor Cyan
Write-Host "══════════════════════════`n" -ForegroundColor DarkCyan

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "❌ PowerShell 7.0 or higher is required" -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "`nPlease install PowerShell 7 from: https://aka.ms/powershell" -ForegroundColor Cyan
    exit 1
}

# Menu for setup options
Write-Host "Choose setup option:" -ForegroundColor Yellow
Write-Host "1. " -NoNewline -ForegroundColor White
Write-Host "Quick Setup (Recommended)" -ForegroundColor Green
Write-Host "2. " -NoNewline -ForegroundColor White
Write-Host "Full Setup with all features" -ForegroundColor Cyan
Write-Host "3. " -NoNewline -ForegroundColor White
Write-Host "Minimal Setup (structure only)" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Enter choice (1-3)"

# Determine which script to run
$scriptToRun = switch ($choice) {
    "1" { ".\Bushido-NFT-Setup.ps1" }
    "2" { ".\Bushido-Enhanced-Setup.ps1" }
    "3" { ".\Bushido-NFT-Setup.ps1 -MinimalSetup" }
    default { 
        Write-Host "Invalid choice. Using Quick Setup..." -ForegroundColor Yellow
        ".\Bushido-NFT-Setup.ps1"
    }
}

# Check if the script exists
$scriptPath = $scriptToRun.Split()[0]
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Script not found: $scriptPath" -ForegroundColor Red
    Write-Host "Make sure you have saved the setup scripts in the current directory." -ForegroundColor Yellow
    exit 1
}

# Run the selected script
Write-Host "`n🚀 Running: $scriptToRun" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════`n" -ForegroundColor DarkCyan

try {
    Invoke-Expression $scriptToRun
} catch {
    Write-Host "`n❌ Error running setup: $_" -ForegroundColor Red
    exit 1
}