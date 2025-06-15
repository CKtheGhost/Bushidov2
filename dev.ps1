#!/usr/bin/env pwsh
# Bushido NFT Development Launcher

param(
    [switch]$NoBrowser
)

Write-Host "`n🏯 Bushido NFT Development Environment" -ForegroundColor Red
Write-Host "══════════════════════════════════════`n" -ForegroundColor DarkRed

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  Creating .env from template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env" -Force
    Write-Host "📝 Configure your .env file before continuing" -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Starting services..." -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost:3000" -ForegroundColor Green
Write-Host "   Backend:  http://localhost:4000" -ForegroundColor Green

if (-not $NoBrowser) {
    Start-Job -ScriptBlock {
        Start-Sleep -Seconds 5
        Start-Process "http://localhost:3000"
    } | Out-Null
}

# Run turbo dev
pnpm run dev
