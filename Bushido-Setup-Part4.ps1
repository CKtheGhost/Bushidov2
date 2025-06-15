# Bushido-Setup-Part4.ps1
# Part 4: Configuration Files and Utility Scripts

param(
    [string]$ProjectPath = (Get-Location).Path,
    [switch]$InstallDependencies
)

#region Helper Functions
function Write-Status {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )
    
    $colors = @{
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error' = 'Red'
    }
    
    $symbols = @{
        'Info' = '►'
        'Success' = '✓'
        'Warning' = '⚠'
        'Error' = '✗'
    }
    
    Write-Host "$($symbols[$Type]) " -NoNewline -ForegroundColor $colors[$Type]
    Write-Host $Message
}

function Write-FileContent {
    param(
        [string]$Path,
        [string]$Content
    )
    
    $directory = Split-Path $Path -Parent
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}
#endregion

#region Configuration Files
function Create-ConfigurationFiles {
    Write-Status "Creating configuration files..." "Info"
    
    # .gitignore
    $gitignore = @'
# Dependencies
node_modules/
.pnpm-store/

# Build outputs
.next/
out/
dist/
build/
artifacts/
cache/
typechain-types/

# Environment
.env
.env*.local

# Logs
logs/
*.log

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Stealth launch
stealth-config.json
kol-list.json
'@
    
    Write-FileContent ".gitignore" $gitignore
    
    # .env.example
    $envExample = @'
# Network Configuration
ABSTRACT_RPC=https://api.abs.xyz
ABSTRACT_TESTNET_RPC=https://api.testnet.abs.xyz
PRIVATE_KEY=your_private_key_here

# Contract Addresses (populated after deployment)
CONTRACT_ADDRESS=
IPFS_BASE_URI=

# Frontend Configuration
NEXT_PUBLIC_NETWORK=abstract
NEXT_PUBLIC_CONTRACT_ADDRESS=
NEXT_PUBLIC_CHAIN_ID=11124
NEXT_PUBLIC_LAUNCH_TIME=2025-01-01T00:00:00Z

# Backend Configuration
PORT=4000
REDIS_URL=redis://localhost:6379

# IPFS/Pinata Configuration
PINATA_API_KEY=
PINATA_SECRET_KEY=

# Analytics
NEXT_PUBLIC_GA_ID=
'@
    
    Write-FileContent ".env.example" $envExample
    
    # .prettierrc
    $prettierConfig = @{
        semi = $true
        singleQuote = $true
        trailingComma = "es5"
        printWidth = 100
        tabWidth = 2
        useTabs = $false
    }
    
    $prettierConfig | ConvertTo-Json -Depth 10 | Set-Content ".prettierrc" -Encoding UTF8
    
    # .eslintrc.json
    $eslintConfig = @{
        extends = @("next/core-web-vitals")
        rules = @{
            "react/no-unescaped-entities" = "off"
        }
    }
    
    $eslintConfig | ConvertTo-Json -Depth 10 | Set-Content ".eslintrc.json" -Encoding UTF8
    
    Write-Status "Configuration files created" "Success"
}

function Create-UtilityScripts {
    Write-Status "Creating utility scripts..." "Info"
    
    # dev.ps1 - Development launcher
    $devScript = @'
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
'@
    
    Write-FileContent "dev.ps1" $devScript
    
    # deploy.ps1 - Deployment helper
    $deployScript = @'
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
'@
    
    Write-FileContent "deploy.ps1" $deployScript
    
    # launch-stealth.ps1 - Stealth launch helper
    $stealthScript = @'
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
'@
    
    Write-FileContent "launch-stealth.ps1" $stealthScript
    
    Write-Status "Utility scripts created" "Success"
}

function Create-StealthLaunchFiles {
    Write-Status "Creating stealth launch files..." "Info"
    
    # Countdown page component
    $countdownComponent = @'
'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

export default function CountdownPage() {
  const [timeLeft, setTimeLeft] = useState({
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  });

  useEffect(() => {
    const launchTime = new Date(process.env.NEXT_PUBLIC_LAUNCH_TIME || '2025-01-01T00:00:00Z');
    
    const timer = setInterval(() => {
      const now = new Date();
      const difference = launchTime.getTime() - now.getTime();
      
      if (difference > 0) {
        setTimeLeft({
          days: Math.floor(difference / (1000 * 60 * 60 * 24)),
          hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
          minutes: Math.floor((difference / 1000 / 60) % 60),
          seconds: Math.floor((difference / 1000) % 60)
        });
      }
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  return (
    <div className="min-h-screen bg-bushido-black flex items-center justify-center">
      <div className="text-center">
        <motion.h1 
          className="text-6xl font-bold text-bushido-red mb-8"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
        >
          武士道
        </motion.h1>
        
        <div className="flex gap-8 justify-center">
          {Object.entries(timeLeft).map(([unit, value]) => (
            <div key={unit} className="text-center">
              <div className="text-4xl font-mono text-white">
                {String(value).padStart(2, '0')}
              </div>
              <div className="text-sm text-gray-500 uppercase">
                {unit}
              </div>
            </div>
          ))}
        </div>
        
        <motion.div
          className="mt-12"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1 }}
        >
          <p className="text-gray-400">
            Eight clans. Eight virtues. One destiny.
          </p>
        </motion.div>
      </div>
    </div>
  );
}
'@
    
    Write-FileContent "frontend/src/app/(stealth)/countdown/page.tsx" $countdownComponent
    
    # Create stealth metadata generator
    $metadataGenerator = @'
import fs from 'fs';
import path from 'path';

const clans = [
  { name: 'Dragon', virtue: 'Courage', color: '#DC2626' },
  { name: 'Phoenix', virtue: 'Rebirth', color: '#EA580C' },
  { name: 'Tiger', virtue: 'Strength', color: '#F59E0B' },
  { name: 'Serpent', virtue: 'Wisdom', color: '#10B981' },
  { name: 'Eagle', virtue: 'Vision', color: '#3B82F6' },
  { name: 'Wolf', virtue: 'Loyalty', color: '#6366F1' },
  { name: 'Bear', virtue: 'Protection', color: '#8B5CF6' },
  { name: 'Lion', virtue: 'Leadership', color: '#EC4899' }
];

const rarities = [
  { name: 'Common', weight: 50 },
  { name: 'Uncommon', weight: 25 },
  { name: 'Rare', weight: 15 },
  { name: 'Epic', weight: 7.5 },
  { name: 'Legendary', weight: 2.5 }
];

function generateMetadata(tokenId) {
  const clanIndex = Math.floor((tokenId - 1) / 200);
  const clan = clans[clanIndex];
  const warriorNumber = ((tokenId - 1) % 200) + 1;
  
  // Determine rarity
  const rand = Math.random() * 100;
  let cumulativeWeight = 0;
  let rarity = 'Common';
  
  for (const r of rarities) {
    cumulativeWeight += r.weight;
    if (rand <= cumulativeWeight) {
      rarity = r.name;
      break;
    }
  }
  
  return {
    name: `Bushido Warrior #${tokenId}`,
    description: `A ${rarity.toLowerCase()} warrior of the ${clan.name} clan, embodying the virtue of ${clan.virtue.toLowerCase()}.`,
    image: `ipfs://QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/${tokenId}.png`,
    attributes: [
      { trait_type: 'Clan', value: clan.name },
      { trait_type: 'Virtue', value: clan.virtue },
      { trait_type: 'Rarity', value: rarity },
      { trait_type: 'Warrior Number', value: warriorNumber }
    ]
  };
}

// Generate all metadata
console.log('Generating metadata for 1600 warriors...');

for (let i = 1; i <= 1600; i++) {
  const metadata = generateMetadata(i);
  const outputPath = path.join('metadata', `${i}.json`);
  
  fs.writeFileSync(outputPath, JSON.stringify(metadata, null, 2));
  
  if (i % 100 === 0) {
    console.log(`Generated ${i}/1600...`);
  }
}

console.log('Metadata generation complete!');
'@
    
    Write-FileContent "scripts/src/generate-metadata.js" $metadataGenerator
    
    Write-Status "Stealth launch files created" "Success"
}
#endregion

#region Main Execution
try {
    Write-Host "`n🏯 Bushido NFT Setup - Part 4 (Final)" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor DarkRed
    
    # Ensure we're in project directory
    if ($ProjectPath -ne (Get-Location).Path) {
        Set-Location $ProjectPath
    }
    
    # Create configuration files
    Create-ConfigurationFiles
    Create-UtilityScripts
    Create-StealthLaunchFiles
    
    # Create metadata directory
    New-Item -ItemType Directory -Path "metadata" -Force | Out-Null
    
    # Final setup steps
    Write-Host "`n📋 Final Setup Steps:" -ForegroundColor Yellow
    
    if ($InstallDependencies) {
        Write-Status "Installing dependencies (this may take a few minutes)..." "Info"
        pnpm install
        Write-Status "Dependencies installed" "Success"
    } else {
        Write-Host "   1. Run 'pnpm install' to install dependencies" -ForegroundColor White
    }
    
    Write-Host "   2. Copy .env.example to .env and configure" -ForegroundColor White
    Write-Host "   3. Run './dev.ps1' to start development" -ForegroundColor White
    Write-Host "   4. Run './deploy.ps1 -Network testnet' to deploy" -ForegroundColor White
    
    Write-Host "`n✨ Setup Complete!" -ForegroundColor Green
    Write-Host "🏯 Your Bushido NFT project is ready for stealth launch!" -ForegroundColor Magenta
    Write-Host "`nRemember: " -NoNewline -ForegroundColor Yellow
    Write-Host "Keep it quiet until launch! 🥷" -ForegroundColor White
    
} catch {
    Write-Status "Setup failed: $_" "Error"
    exit 1
}
#endregion