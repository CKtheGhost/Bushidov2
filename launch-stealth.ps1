#!/usr/bin/env pwsh
# Bushido NFT Stealth Launch

Write-Host "`n🥷 Bushido NFT Stealth Launch" -ForegroundColor Magenta
Write-Host "══════════════════════════════`n" -ForegroundColor DarkMagenta

# Build frontend
Write-Host "📦 Building frontend..." -ForegroundColor Yellow
Push-Location frontend
pnpm run build
Pop-Location

# Deploy to Vercel
Write-Host "`n🚀 Deploying to Vercel..." -ForegroundColor Cyan
vercel --prod

Write-Host "`n✨ Stealth launch deployed!" -ForegroundColor Green
Write-Host "🔗 Share with KOLs only" -ForegroundColor Yellow
