# Bushido-Restructure.ps1
# Restructures the project for stealth launch on Abstract L2

param(
    [string]$ProjectPath = (Get-Location).Path
)

Write-Host "`n🏯 Bushido NFT Project Restructure" -ForegroundColor Red
Write-Host "═══════════════════════════════════════`n" -ForegroundColor DarkRed

# Files to remove (not needed for stealth launch)
$filesToRemove = @(
    "Architecture.md",
    "CompleteTechStack.md", 
    "TransformationGuide.md",
    "BushidoSetupFramework.ps1",
    "BushidoSetupFramework.psm1",
    "BushidoMasterResolver.ps1",
    "Bushido-Enhanced-Setup.ps1",
    "setup-prerequisites-enhanced.ps1",
    "Run-Bushido-Setup.ps1"
)

Write-Host "📦 Cleaning up unnecessary files..." -ForegroundColor Yellow
foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "   ✓ Removed $file" -ForegroundColor Green
    }
}

# Create stealth launch specific structure
Write-Host "`n📁 Creating stealth launch structure..." -ForegroundColor Yellow

# Create directories
$directories = @(
    "contracts/interfaces",
    "contracts/libraries", 
    "frontend/src/app/(stealth)",
    "frontend/src/components/countdown",
    "frontend/src/components/mint",
    "frontend/src/hooks",
    "backend/src/routes",
    "backend/src/services",
    "scripts/stealth",
    "docs/internal",
    "metadata/clans"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "   ✓ Created $dir" -ForegroundColor Green
}

# Create stealth-specific config
$stealthConfig = @"
{
  "launch": {
    "mode": "stealth",
    "revealPhases": {
      "mint": {
        "duration": "72h",
        "reveal": ["basic_info", "mint_button"]
      },
      "postMint": {
        "trigger": "soldout",
        "reveal": ["full_lore", "voting_system", "clan_details"]
      },
      "episode1": {
        "trigger": "1_week_post_mint",
        "reveal": ["first_episode", "voting_interface"]
      }
    },
    "kols": {
      "earlyAccess": true,
      "count": 15,
      "seedRarities": ["legendary", "epic"]
    }
  },
  "collection": {
    "totalSupply": 1600,
    "clansCount": 8,
    "perClan": 200,
    "mintPrice": "0.08",
    "maxPerWallet": 3,
    "rarityTiers": {
      "Common": { "count": 800, "votingPower": 1 },
      "Uncommon": { "count": 400, "votingPower": 4 },
      "Rare": { "count": 240, "votingPower": 9 },
      "Epic": { "count": 120, "votingPower": 16 },
      "Legendary": { "count": 40, "votingPower": 25 }
    }
  },
  "clans": [
    { "id": 0, "name": "Dragon", "virtue": "Courage", "color": "#DC2626" },
    { "id": 1, "name": "Phoenix", "virtue": "Rebirth", "color": "#EA580C" },
    { "id": 2, "name": "Tiger", "virtue": "Strength", "color": "#F59E0B" },
    { "id": 3, "name": "Serpent", "virtue": "Wisdom", "color": "#10B981" },
    { "id": 4, "name": "Eagle", "virtue": "Vision", "color": "#3B82F6" },
    { "id": 5, "name": "Wolf", "virtue": "Loyalty", "color": "#6366F1" },
    { "id": 6, "name": "Bear", "virtue": "Protection", "color": "#8B5CF6" },
    { "id": 7, "name": "Lion", "virtue": "Leadership", "color": "#EC4899" }
  ]
}
"@

Set-Content -Path "stealth-config.json" -Value $stealthConfig -Encoding UTF8
Write-Host "`n✓ Created stealth configuration" -ForegroundColor Green

# Update README for stealth launch
$readme = @"
# 🏯 Bushido NFT Collection

## Stealth Launch on Abstract

*Eight clans. Eight virtues. One destiny.*

### Quick Start

\`\`\`bash
# Install dependencies
pnpm install

# Configure environment
cp .env.example .env

# Deploy to Abstract testnet
pnpm deploy:testnet

# Launch stealth site
pnpm launch:stealth
\`\`\`

### Launch Strategy

1. **Stealth Drop**: No roadmap, minimal information
2. **KOL Seeding**: 10-15 influencers mint early
3. **Post-Mint Reveal**: Full lore and voting mechanics
4. **Episode 1**: One week after sellout

### The Eight Clans

- 🐲 Dragon - Courage
- 🔥 Phoenix - Rebirth  
- 🐯 Tiger - Strength
- 🐍 Serpent - Wisdom
- 🦅 Eagle - Vision
- 🐺 Wolf - Loyalty
- 🐻 Bear - Protection
- 🦁 Lion - Leadership

---

*"Where art meets anime. Where ownership meets narrative. Where legends are born."*
"@

Set-Content -Path "README.md" -Value $readme -Encoding UTF8
Write-Host "✓ Updated README for stealth launch" -ForegroundColor Green

Write-Host "`n✨ Restructure complete!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Run the setup scripts in sections" -ForegroundColor White
Write-Host "   2. Configure stealth countdown page" -ForegroundColor White
Write-Host "   3. Set up KOL distribution list" -ForegroundColor White