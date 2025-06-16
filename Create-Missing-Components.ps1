# Create-Missing-Components.ps1
# Script to create placeholder components for Bushido NFT frontend

param(
    [string]$FrontendPath = (Join-Path (Get-Location).Path "frontend")
)

Write-Host "🔧 Creating Missing Components for Bushido NFT" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

if (-not (Test-Path $FrontendPath)) {
    Write-Host "❌ Frontend directory not found at: $FrontendPath" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Working in: $FrontendPath" -ForegroundColor Gray

# Component definitions
$components = @{
    "src/components/countdown/CountdownTimer.tsx" = @'
"use client";

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

interface CountdownTimerProps {
  targetDate: Date;
}

export default function CountdownTimer({ targetDate }: CountdownTimerProps) {
  const [timeLeft, setTimeLeft] = useState({
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  });

  useEffect(() => {
    const calculateTimeLeft = () => {
      const difference = targetDate.getTime() - new Date().getTime();
      
      if (difference > 0) {
        setTimeLeft({
          days: Math.floor(difference / (1000 * 60 * 60 * 24)),
          hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
          minutes: Math.floor((difference / 1000 / 60) % 60),
          seconds: Math.floor((difference / 1000) % 60)
        });
      }
    };

    calculateTimeLeft();
    const timer = setInterval(calculateTimeLeft, 1000);

    return () => clearInterval(timer);
  }, [targetDate]);

  return (
    <div className="flex gap-4 justify-center my-8">
      {Object.entries(timeLeft).map(([unit, value]) => (
        <motion.div
          key={unit}
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.1 * Object.keys(timeLeft).indexOf(unit) }}
          className="text-center"
        >
          <div className="bg-gray-900 border border-gray-800 rounded-lg p-4 min-w-[80px]">
            <motion.div
              key={value}
              initial={{ y: -20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              className="text-3xl font-bold text-white"
            >
              {value.toString().padStart(2, '0')}
            </motion.div>
            <div className="text-xs text-gray-500 uppercase mt-1">{unit}</div>
          </div>
        </motion.div>
      ))}
    </div>
  );
}
'@

    "src/components/clan/ClanSymbols.tsx" = @'
"use client";

import { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';

const clanKanji = ['忠', '義', '礼', '智', '信', '仁', '勇', '誠'];
const clanColors = [
  '#DC2626', '#F59E0B', '#10B981', '#3B82F6', 
  '#8B5CF6', '#EC4899', '#06B6D4', '#F97316'
];

export default function ClanSymbols() {
  const groupRef = useRef<THREE.Group>(null);

  useFrame((state) => {
    if (groupRef.current) {
      groupRef.current.rotation.y = state.clock.getElapsedTime() * 0.1;
    }
  });

  return (
    <group ref={groupRef}>
      {clanKanji.map((kanji, index) => {
        const angle = (index / 8) * Math.PI * 2;
        const radius = 3;
        const x = Math.cos(angle) * radius;
        const z = Math.sin(angle) * radius;

        return (
          <mesh key={index} position={[x, 0, z]}>
            <planeGeometry args={[1, 1]} />
            <meshBasicMaterial 
              color={clanColors[index]} 
              transparent 
              opacity={0.3}
            />
          </mesh>
        );
      })}
    </group>
  );
}
'@

    "src/components/collection/CollectionGrid.tsx" = @'
"use client";

import { useState } from 'react';
import { motion } from 'framer-motion';

export default function CollectionGrid() {
  const [selectedNFT, setSelectedNFT] = useState<number | null>(null);

  // Placeholder NFT data
  const placeholderNFTs = Array.from({ length: 16 }, (_, i) => ({
    id: i + 1,
    name: `Bushido Warrior #${i + 1}`,
    clan: ['Honor', 'Courage', 'Wisdom', 'Loyalty', 'Justice', 'Benevolence', 'Respect', 'Honesty'][i % 8],
    rarity: ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'][Math.floor(Math.random() * 5)]
  }));

  return (
    <div className="container mx-auto px-4 py-12">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center mb-12"
      >
        <h1 className="text-5xl font-bold mb-4">Bushido Collection</h1>
        <p className="text-xl text-gray-400">1,600 unique warriors across 8 clans</p>
      </motion.div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {placeholderNFTs.map((nft, index) => (
          <motion.div
            key={nft.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.05 }}
            className="bg-neutral-900 rounded-xl overflow-hidden border border-red-900/20 hover:border-red-500 transition-all cursor-pointer transform hover:scale-105"
            onClick={() => setSelectedNFT(nft.id)}
          >
            <div className="h-64 bg-gradient-to-br from-red-900/20 to-black flex items-center justify-center">
              <div className="text-6xl opacity-50">侍</div>
            </div>
            <div className="p-4">
              <h3 className="text-lg font-bold mb-1">{nft.name}</h3>
              <p className="text-gray-400 text-sm">Clan: {nft.clan}</p>
              <p className="text-gray-400 text-sm">Rarity: {nft.rarity}</p>
            </div>
          </motion.div>
        ))}
      </div>

      {/* NFT Detail Modal */}
      {selectedNFT && (
        <div 
          className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4"
          onClick={() => setSelectedNFT(null)}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-neutral-900 rounded-xl p-8 max-w-md w-full"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-2xl font-bold mb-4">Bushido Warrior #{selectedNFT}</h2>
            <div className="h-64 bg-gradient-to-br from-red-900/20 to-black rounded-lg mb-4 flex items-center justify-center">
              <div className="text-8xl">侍</div>
            </div>
            <div className="space-y-2 text-gray-400">
              <p>Clan: {placeholderNFTs[selectedNFT - 1]?.clan}</p>
              <p>Rarity: {placeholderNFTs[selectedNFT - 1]?.rarity}</p>
              <p>Voting Power: 3</p>
            </div>
            <button
              onClick={() => setSelectedNFT(null)}
              className="mt-6 w-full px-4 py-2 bg-red-600 hover:bg-red-500 rounded-lg transition-colors"
            >
              Close
            </button>
          </motion.div>
        </div>
      )}
    </div>
  );
}
'@

    "src/components/layout/Layout.tsx" = @'
"use client";

import { ReactNode } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';

interface LayoutProps {
  children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  const pathname = usePathname();

  const navigation = [
    { name: 'Collection', href: '/collection' },
    { name: 'Animated Series', href: '/animated-series' },
    { name: 'Community', href: '/community' }
  ];

  return (
    <div className="min-h-screen bg-black text-white">
      <nav className="fixed top-0 w-full z-50 bg-black/90 backdrop-blur-sm border-b border-red-900/20">
        <div className="container mx-auto px-4 py-4 flex justify-between items-center">
          <Link href="/" className="flex items-center gap-2">
            <span className="text-red-500 text-3xl font-bold">武士道</span>
            <h1 className="text-2xl font-bold">BUSHIDO</h1>
          </Link>
          
          <div className="flex items-center gap-6">
            <div className="flex gap-4">
              {navigation.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`px-4 py-2 rounded-lg transition-colors ${
                    pathname === item.href
                      ? 'bg-red-600 text-white'
                      : 'text-gray-400 hover:text-white'
                  }`}
                >
                  {item.name}
                </Link>
              ))}
            </div>
            
            <button className="px-6 py-3 bg-red-700 hover:bg-red-600 rounded-xl flex items-center gap-2 transition-colors">
              Connect Wallet
            </button>
          </div>
        </div>
      </nav>

      <main className="pt-20">
        {children}
      </main>
    </div>
  );
}
'@

    "src/app/animated-series/page.tsx" = @'
"use client";

import Layout from '@/components/layout/Layout';
import { motion } from 'framer-motion';

export default function AnimatedSeriesPage() {
  return (
    <Layout>
      <div className="container mx-auto px-4 py-12">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-12"
        >
          <h1 className="text-5xl font-bold mb-4">Animated Series</h1>
          <p className="text-xl text-gray-400">Vote on the story direction with your NFTs</p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          <div className="bg-neutral-900/50 rounded-xl p-6 border border-red-900/20">
            <h3 className="text-2xl font-bold mb-4">Episode 1: Origins</h3>
            <p className="text-gray-400 mb-4">The first warriors discover ancient artifacts...</p>
            <div className="flex justify-between items-center">
              <span className="text-green-500">Released</span>
              <button className="px-4 py-2 bg-red-600 hover:bg-red-500 rounded-lg">Watch</button>
            </div>
          </div>

          <div className="bg-neutral-900/50 rounded-xl p-6 border border-red-900/20">
            <h3 className="text-2xl font-bold mb-4">Episode 2: The Choice</h3>
            <p className="text-gray-400 mb-4">Warriors must choose their path...</p>
            <div className="flex justify-between items-center">
              <span className="text-blue-500">Voting Active</span>
              <button className="px-4 py-2 bg-blue-600 hover:bg-blue-500 rounded-lg">Vote Now</button>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
'@

    "src/app/community/page.tsx" = @'
"use client";

import Layout from '@/components/layout/Layout';
import { motion } from 'framer-motion';

export default function CommunityPage() {
  return (
    <Layout>
      <div className="container mx-auto px-4 py-12">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-12"
        >
          <h1 className="text-5xl font-bold mb-4">Join the Community</h1>
          <p className="text-xl text-gray-400">Shape the future of Bushido together</p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto">
          <div className="bg-neutral-900/50 rounded-xl p-8 text-center border border-red-900/20 hover:border-red-500 transition-all">
            <h3 className="text-2xl font-bold mb-2">Discord</h3>
            <p className="text-gray-400 mb-4">12,543 members</p>
            <button className="px-6 py-3 bg-red-600 hover:bg-red-500 rounded-lg w-full">Join Discord</button>
          </div>

          <div className="bg-neutral-900/50 rounded-xl p-8 text-center border border-red-900/20 hover:border-red-500 transition-all">
            <h3 className="text-2xl font-bold mb-2">Twitter</h3>
            <p className="text-gray-400 mb-4">45,231 followers</p>
            <button className="px-6 py-3 bg-red-600 hover:bg-red-500 rounded-lg w-full">Follow</button>
          </div>

          <div className="bg-neutral-900/50 rounded-xl p-8 text-center border border-red-900/20 hover:border-red-500 transition-all">
            <h3 className="text-2xl font-bold mb-2">Telegram</h3>
            <p className="text-gray-400 mb-4">8,932 members</p>
            <button className="px-6 py-3 bg-red-600 hover:bg-red-500 rounded-lg w-full">Join Telegram</button>
          </div>
        </div>
      </div>
    </Layout>
  );
}
'@
}

# Create each component
foreach ($component in $components.GetEnumerator()) {
    $componentPath = Join-Path $FrontendPath $component.Key
    $componentDir = Split-Path $componentPath -Parent
    
    # Create directory if it doesn't exist
    if (-not (Test-Path $componentDir)) {
        New-Item -ItemType Directory -Path $componentDir -Force | Out-Null
    }
    
    # Write component file
    Set-Content -Path $componentPath -Value $component.Value -Encoding UTF8
    Write-Host "✓ Created: $($component.Key)" -ForegroundColor Green
}

# Install required dependencies if not present
Write-Host "`n📦 Checking dependencies..." -ForegroundColor Yellow

$packageJsonPath = Join-Path $FrontendPath "package.json"
$packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json

$requiredDeps = @{
    "framer-motion" = "^10.16.4"
    "@react-three/fiber" = "^8.15.11"
    "@react-three/drei" = "^9.88.17"
    "three" = "^0.159.0"
}

$depsToInstall = @()
foreach ($dep in $requiredDeps.GetEnumerator()) {
    if (-not $packageJson.dependencies.PSObject.Properties[$dep.Key]) {
        $depsToInstall += $dep.Key
    }
}

if ($depsToInstall.Count -gt 0) {
    Write-Host "Installing missing dependencies: $($depsToInstall -join ', ')" -ForegroundColor Yellow
    Set-Location $FrontendPath
    & pnpm add $depsToInstall
} else {
    Write-Host "All required dependencies are already installed" -ForegroundColor Green
}

Write-Host "`n✨ All components created successfully!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "`nYour application structure is now complete with:" -ForegroundColor Cyan
Write-Host "  • Countdown timer for stealth phase" -ForegroundColor White
Write-Host "  • 3D clan symbols animation" -ForegroundColor White
Write-Host "  • Collection grid with placeholder NFTs" -ForegroundColor White
Write-Host "  • Layout component with navigation" -ForegroundColor White
Write-Host "  • Animated series and community pages" -ForegroundColor White
Write-Host "`n🚀 Run 'pnpm run dev' to start your development server" -ForegroundColor Yellow