# Fix-Bushido-Routing.ps1
# Script to resolve Next.js routing conflicts and implement phase-based rendering

param(
    [string]$ProjectPath = (Get-Location).Path
)

Write-Host "🔧 Fixing Bushido NFT Frontend Routing Structure" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Ensure we're in the frontend directory
$frontendPath = Join-Path $ProjectPath "frontend"
if (-not (Test-Path $frontendPath)) {
    Write-Host "❌ Frontend directory not found. Please run from project root." -ForegroundColor Red
    exit 1
}

Set-Location $frontendPath
Write-Host "📁 Working in: $frontendPath" -ForegroundColor Gray

# Step 1: Create backup directory
$backupDir = Join-Path $frontendPath "backup-routing-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Host "✅ Created backup directory: $backupDir" -ForegroundColor Green

# Step 2: Backup existing files
Write-Host "`n📦 Backing up existing files..." -ForegroundColor Yellow

$filesToBackup = @(
    "src/app/page.tsx",
    "src/app/(stealth)/page.tsx",
    "src/app/layout.tsx",
    ".env.local"
)

foreach ($file in $filesToBackup) {
    $sourcePath = Join-Path $frontendPath $file
    if (Test-Path $sourcePath) {
        $destPath = Join-Path $backupDir $file
        $destDir = Split-Path $destPath -Parent
        New-Item -ItemType Directory -Path $destDir -Force -ErrorAction SilentlyContinue | Out-Null
        Copy-Item -Path $sourcePath -Destination $destPath -Force
        Write-Host "  ✓ Backed up: $file" -ForegroundColor Gray
    }
}

# Step 3: Create components directory structure
Write-Host "`n📁 Creating component structure..." -ForegroundColor Yellow

$directories = @(
    "src/components/stealth",
    "src/components/layout",
    "src/app/collection",
    "src/app/animated-series",
    "src/app/community"
)

foreach ($dir in $directories) {
    $dirPath = Join-Path $frontendPath $dir
    New-Item -ItemType Directory -Path $dirPath -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  ✓ Created: $dir" -ForegroundColor Gray
}

# Step 4: Move stealth page to components
Write-Host "`n🚀 Restructuring stealth components..." -ForegroundColor Yellow

$stealthSource = Join-Path $frontendPath "src/app/(stealth)/page.tsx"
$stealthDest = Join-Path $frontendPath "src/components/stealth/StealthLanding.tsx"

if (Test-Path $stealthSource) {
    # Read the content and update export
    $content = Get-Content $stealthSource -Raw
    $content = $content -replace "export default function \w+", "export default function StealthLanding"
    Set-Content -Path $stealthDest -Value $content -Encoding UTF8
    Remove-Item $stealthSource -Force
    Write-Host "  ✓ Moved stealth page to components" -ForegroundColor Gray
}

# Step 5: Create new root page with conditional logic
Write-Host "`n📝 Creating new root page with phase control..." -ForegroundColor Yellow

$rootPageContent = @'
"use client";

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import StealthLanding from '@/components/stealth/StealthLanding';

export default function HomePage() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [isStealthPhase, setIsStealthPhase] = useState(true);

  useEffect(() => {
    // Check launch time
    const launchTime = new Date(process.env.NEXT_PUBLIC_LAUNCH_TIME || '2025-01-20T00:00:00Z');
    const currentTime = new Date();
    
    // Development override
    const forceReveal = process.env.NEXT_PUBLIC_FORCE_REVEAL === 'true';
    const phase = process.env.NEXT_PUBLIC_PHASE;
    
    if (forceReveal || phase === 'reveal' || currentTime >= launchTime) {
      // Redirect to main app
      router.push('/collection');
    } else {
      setIsStealthPhase(true);
      setIsLoading(false);
    }
  }, [router]);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-black flex items-center justify-center">
        <div className="text-white">Loading...</div>
      </div>
    );
  }

  return <StealthLanding />;
}
'@

$rootPagePath = Join-Path $frontendPath "src/app/page.tsx"
Set-Content -Path $rootPagePath -Value $rootPageContent -Encoding UTF8
Write-Host "  ✓ Created new root page with conditional logic" -ForegroundColor Gray

# Step 6: Create collection page if it doesn't exist
$collectionPagePath = Join-Path $frontendPath "src/app/collection/page.tsx"
if (-not (Test-Path $collectionPagePath)) {
    Write-Host "`n📝 Creating collection page..." -ForegroundColor Yellow
    
    $collectionContent = @'
"use client";

import CollectionGrid from '@/components/collection/CollectionGrid';
import Layout from '@/components/layout/Layout';

export default function CollectionPage() {
  return (
    <Layout>
      <CollectionGrid />
    </Layout>
  );
}
'@
    
    Set-Content -Path $collectionPagePath -Value $collectionContent -Encoding UTF8
    Write-Host "  ✓ Created collection page" -ForegroundColor Gray
}

# Step 7: Update or create .env.local
Write-Host "`n⚙️  Updating environment configuration..." -ForegroundColor Yellow

$envPath = Join-Path $frontendPath ".env.local"
$envContent = @"
# Bushido NFT Environment Configuration
# =====================================

# Contract Configuration
NEXT_PUBLIC_CONTRACT_ADDRESS=0x0000000000000000000000000000000000000000
NEXT_PUBLIC_ABSTRACT_RPC=https://api.testnet.abs.xyz

# WebSocket for Voting
NEXT_PUBLIC_WS_URL=http://localhost:4000

# Launch Configuration
NEXT_PUBLIC_LAUNCH_TIME=2025-01-20T00:00:00Z

# Development Controls
# Set NEXT_PUBLIC_PHASE to 'stealth' or 'reveal' to control display
NEXT_PUBLIC_PHASE=reveal
NEXT_PUBLIC_FORCE_REVEAL=false

# IPFS/Pinata Configuration
NEXT_PUBLIC_PINATA_GATEWAY=https://gateway.pinata.cloud

# Optional: Force specific view for development
# NEXT_PUBLIC_DEV_MODE=true
"@

# If .env.local exists, append our new variables
if (Test-Path $envPath) {
    $existingContent = Get-Content $envPath -Raw
    if ($existingContent -notmatch "NEXT_PUBLIC_PHASE") {
        Add-Content -Path $envPath -Value "`n$envContent" -Encoding UTF8
        Write-Host "  ✓ Appended new environment variables" -ForegroundColor Gray
    } else {
        Write-Host "  ℹ Environment variables already configured" -ForegroundColor Yellow
    }
} else {
    Set-Content -Path $envPath -Value $envContent -Encoding UTF8
    Write-Host "  ✓ Created .env.local with configuration" -ForegroundColor Gray
}

# Step 8: Clean up old route group structure
Write-Host "`n🧹 Cleaning up old structure..." -ForegroundColor Yellow

$stealthDir = Join-Path $frontendPath "src/app/(stealth)"
if (Test-Path $stealthDir) {
    $remainingFiles = Get-ChildItem $stealthDir -File
    if ($remainingFiles.Count -eq 0) {
        Remove-Item $stealthDir -Recurse -Force
        Write-Host "  ✓ Removed empty (stealth) directory" -ForegroundColor Gray
    } else {
        Write-Host "  ℹ (stealth) directory contains other files, not removing" -ForegroundColor Yellow
    }
}

# Step 9: Create a development control script
Write-Host "`n📝 Creating development control script..." -ForegroundColor Yellow

$devScriptContent = @'
#!/usr/bin/env pwsh
# Toggle between stealth and reveal phases for development

param(
    [ValidateSet("stealth", "reveal", "toggle")]
    [string]$Phase = "toggle"
)

$envFile = ".env.local"
$content = Get-Content $envFile -Raw

if ($Phase -eq "toggle") {
    if ($content -match "NEXT_PUBLIC_PHASE=reveal") {
        $Phase = "stealth"
    } else {
        $Phase = "reveal"
    }
}

$content = $content -replace "NEXT_PUBLIC_PHASE=\w+", "NEXT_PUBLIC_PHASE=$Phase"
Set-Content -Path $envFile -Value $content -Encoding UTF8

Write-Host "✅ Switched to $Phase phase" -ForegroundColor Green
Write-Host "🔄 Restart your dev server to see changes" -ForegroundColor Yellow
'@

$devScriptPath = Join-Path $frontendPath "toggle-phase.ps1"
Set-Content -Path $devScriptPath -Value $devScriptContent -Encoding UTF8
Write-Host "  ✓ Created toggle-phase.ps1 for easy phase switching" -ForegroundColor Gray

# Final summary
Write-Host "`n✨ Routing restructure complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "`n📋 Summary of changes:" -ForegroundColor Cyan
Write-Host "  • Moved stealth page to components" -ForegroundColor White
Write-Host "  • Created conditional root page" -ForegroundColor White
Write-Host "  • Set up proper route structure" -ForegroundColor White
Write-Host "  • Configured environment variables" -ForegroundColor White
Write-Host "  • Created phase toggle script" -ForegroundColor White

Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run 'pnpm run dev' to start the development server" -ForegroundColor White
Write-Host "  2. Visit http://localhost:3000 to see your app" -ForegroundColor White
Write-Host "  3. Use './toggle-phase.ps1' to switch between stealth/reveal" -ForegroundColor White
Write-Host "  4. Check .env.local to adjust launch settings" -ForegroundColor White

Write-Host "`n💾 Backup location: $backupDir" -ForegroundColor Gray
Write-Host "`n✅ Happy developing!" -ForegroundColor Green