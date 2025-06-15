#!/usr/bin/env pwsh
# Bushido NFT Deployment Script

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("testnet", "mainnet")]
    [string]$Network
)

Write-Host "`n🏯 Bushido NFT Deployment" -ForegroundColor Red
Write-Host "══════════════════════════════`n" -ForegroundColor DarkRed

# Check environment
if (-not (Test-Path ".env")) {
    Write-Host "❌ Missing .env file" -ForegroundColor Red
    exit 1
}

# Load environment
$env:NETWORK = $Network
Write-Host "📡 Deploying to $Network..." -ForegroundColor Cyan

# Build contracts
Write-Host "`n📦 Building contracts..." -ForegroundColor Yellow
Push-Location contracts
pnpm run compile
Pop-Location

# Deploy
Write-Host "`n🚀 Deploying..." -ForegroundColor Yellow
pnpm run deploy:$Network

Write-Host "`n✨ Deployment complete!" -ForegroundColor Green
