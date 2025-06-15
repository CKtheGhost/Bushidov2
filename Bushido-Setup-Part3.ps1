# Bushido-Setup-Part3.ps1
# Part 3: Frontend and Backend Package Setup

param(
    [string]$ProjectPath = (Get-Location).Path
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

#region Frontend Setup
function Create-FrontendPackage {
    Write-Status "Setting up frontend package..." "Info"
    
    Push-Location "frontend"
    try {
        # Package.json for frontend
        $package = @{
            name = "@bushido/frontend"
            version = "1.0.0"
            private = $true
            scripts = @{
                "dev" = "next dev"
                "build" = "next build"
                "start" = "next start"
                "lint" = "next lint"
                "typecheck" = "tsc --noEmit"
            }
            dependencies = @{
                "next" = "14.0.4"
                "react" = "^18.2.0"
                "react-dom" = "^18.2.0"
                "@rainbow-me/rainbowkit" = "^2.0.0"
                "wagmi" = "^2.0.0"
                "viem" = "^2.0.0"
                "@tanstack/react-query" = "^5.17.0"
                "ethers" = "^6.10.0"
                "framer-motion" = "^10.18.0"
                "three" = "^0.160.0"
                "@react-three/fiber" = "^8.15.0"
                "@react-three/drei" = "^9.96.0"
                "tailwindcss" = "^3.4.0"
                "clsx" = "^2.1.0"
                "axios" = "^1.6.5"
            }
            devDependencies = @{
                "@types/node" = "^20.11.0"
                "@types/react" = "^18.2.48"
                "@types/react-dom" = "^18.2.18"
                "typescript" = "^5.3.3"
                "autoprefixer" = "^10.4.17"
                "postcss" = "^8.4.33"
                "eslint" = "^8.56.0"
                "eslint-config-next" = "14.0.4"
            }
        }
        
        $package | ConvertTo-Json -Depth 10 | Set-Content "package.json" -Encoding UTF8
        
        # Next.js config
        $nextConfig = @'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['ipfs.io', 'gateway.pinata.cloud'],
    unoptimized: process.env.NODE_ENV === 'development'
  },
  webpack: (config) => {
    config.resolve.fallback = { fs: false, net: false, tls: false };
    return config;
  }
};

module.exports = nextConfig;
'@
        
        Write-FileContent "next.config.js" $nextConfig
        
        # TypeScript config
        $tsConfig = @{
            compilerOptions = @{
                target = "es5"
                lib = @("dom", "dom.iterable", "esnext")
                allowJs = $true
                skipLibCheck = $true
                strict = $true
                forceConsistentCasingInFileNames = $true
                noEmit = $true
                esModuleInterop = $true
                module = "esnext"
                moduleResolution = "node"
                resolveJsonModule = $true
                isolatedModules = $true
                jsx = "preserve"
                incremental = $true
                paths = @{
                    "@/*" = @("./src/*")
                }
            }
            include = @("next-env.d.ts", "**/*.ts", "**/*.tsx")
            exclude = @("node_modules")
        }
        
        $tsConfig | ConvertTo-Json -Depth 10 | Set-Content "tsconfig.json" -Encoding UTF8
        
        # Tailwind config
        $tailwindConfig = @'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        bushido: {
          red: '#DC2626',
          black: '#0F0F0F',
          gold: '#FFD700',
        }
      },
      fontFamily: {
        'japanese': ['Noto Sans JP', 'sans-serif'],
      },
      animation: {
        'float': 'float 6s ease-in-out infinite',
        'pulse-slow': 'pulse 4s ease-in-out infinite',
      }
    },
  },
  plugins: [],
}
'@
        
        Write-FileContent "tailwind.config.js" $tailwindConfig
        
        # Create app layout
        $layout = @'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Bushido NFT',
  description: 'Eight clans. Eight virtues. One destiny.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
'@
        
        Write-FileContent "src/app/layout.tsx" $layout
        
        # Create globals.css
        $globalsCss = @'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply bg-bushido-black text-white;
  }
}

@layer utilities {
  @keyframes float {
    0%, 100% { transform: translateY(0px); }
    50% { transform: translateY(-20px); }
  }
}
'@
        
        Write-FileContent "src/app/globals.css" $globalsCss
        
        Write-Status "Frontend package created" "Success"
        
    } finally {
        Pop-Location
    }
}

function Create-BackendPackage {
    Write-Status "Setting up backend package..." "Info"
    
    Push-Location "backend"
    try {
        # Package.json for backend
        $package = @{
            name = "@bushido/backend"
            version = "1.0.0"
            private = $true
            type = "module"
            scripts = @{
                "dev" = "nodemon src/index.js"
                "start" = "node src/index.js"
                "test" = "jest"
            }
            dependencies = @{
                "express" = "^4.18.2"
                "cors" = "^2.8.5"
                "helmet" = "^7.1.0"
                "ethers" = "^6.10.0"
                "redis" = "^4.6.12"
                "dotenv" = "^16.3.1"
            }
            devDependencies = @{
                "nodemon" = "^3.0.2"
                "jest" = "^29.7.0"
            }
        }
        
        $package | ConvertTo-Json -Depth 10 | Set-Content "package.json" -Encoding UTF8
        
        # Create main server file
        $serverCode = @'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Metadata endpoint
app.get('/api/metadata/:tokenId', async (req, res) => {
  const { tokenId } = req.params;
  
  // Calculate clan and warrior number
  const clan = Math.floor((parseInt(tokenId) - 1) / 200);
  const warriorInClan = ((parseInt(tokenId) - 1) % 200) + 1;
  
  const clans = [
    'Dragon', 'Phoenix', 'Tiger', 'Serpent',
    'Eagle', 'Wolf', 'Bear', 'Lion'
  ];
  
  const metadata = {
    name: `Bushido Warrior #${tokenId}`,
    description: `A legendary warrior of the ${clans[clan]} clan.`,
    image: `ipfs://QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/${tokenId}.png`,
    attributes: [
      {
        trait_type: 'Clan',
        value: clans[clan]
      },
      {
        trait_type: 'Warrior Number',
        value: warriorInClan
      }
    ]
  };
  
  res.json(metadata);
});

// Voting endpoints
app.get('/api/episodes/:episodeId/votes', async (req, res) => {
  // Return current vote tallies
  res.json({
    episodeId: req.params.episodeId,
    options: [],
    totalVotes: 0
  });
});

app.post('/api/episodes/:episodeId/vote', async (req, res) => {
  // Process vote
  res.json({ success: true });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
'@
        
        Write-FileContent "src/index.js" $serverCode
        
        Write-Status "Backend package created" "Success"
        
    } finally {
        Pop-Location
    }
}

function Create-ScriptsPackage {
    Write-Status "Setting up scripts package..." "Info"
    
    Push-Location "scripts"
    try {
        # Package.json for scripts
        $package = @{
            name = "@bushido/scripts"
            version = "1.0.0"
            private = $true
            type = "module"
            scripts = @{
                "generate-metadata" = "node src/generate-metadata.js"
                "upload-ipfs" = "node src/upload-ipfs.js"
            }
            devDependencies = @{
                "ipfs-http-client" = "^60.0.1"
                "chalk" = "^5.3.0"
            }
        }
        
        $package | ConvertTo-Json -Depth 10 | Set-Content "package.json" -Encoding UTF8
        
        Write-Status "Scripts package created" "Success"
        
    } finally {
        Pop-Location
    }
}
#endregion

#region Main Execution
try {
    Write-Host "`n🏯 Bushido NFT Setup - Part 3" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor DarkRed
    
    # Ensure we're in project directory
    if ($ProjectPath -ne (Get-Location).Path) {
        Set-Location $ProjectPath
    }
    
    # Create packages
    Create-FrontendPackage
    Create-BackendPackage
    Create-ScriptsPackage
    
    Write-Host "`n✨ Part 3 Complete!" -ForegroundColor Green
    Write-Host "Run Part 4 to create configuration files and utilities`n" -ForegroundColor Yellow
    
} catch {
    Write-Status "Setup failed: $_" "Error"
    exit 1
}
#endregion