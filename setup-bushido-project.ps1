# setup-bushido-project.ps1
# Bushido NFT Complete Project Setup
# PowerShell 7.5.1+ Compatible

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = "C:\Users\$env:USERNAME\bushido-nft",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDependencies
)

$ErrorActionPreference = "Stop"

# Import utility functions
function Write-BushidoStatus {
    param(
        [string]$Message,
        [string]$Type = "Info",
        [int]$Indent = 0
    )
    $prefix = " " * $Indent
    $colors = @{
        "Info" = "Cyan"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error" = "Red"
        "Special" = "Magenta"
    }
    Write-Host "$prefix[$(Get-Date -Format 'HH:mm:ss')] " -ForegroundColor DarkGray -NoNewline
    Write-Host "[$Type] " -ForegroundColor $colors[$Type] -NoNewline
    Write-Host $Message
}

function New-BushidoFile {
    param(
        [string]$Path,
        [string]$Content = "",
        [switch]$Force
    )
    
    $directory = Split-Path -Parent $Path
    if ($directory -and !(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    if ($Force -or !(Test-Path $Path)) {
        Set-Content -Path $Path -Value $Content -Encoding UTF8
        Write-BushidoStatus "Created: $($Path.Replace($ProjectRoot, '.'))" "Success" 2
    }
}

function Initialize-ProjectStructure {
    Write-BushidoStatus "Initializing Bushido NFT project structure..." "Special"
    
    # Create main project directory
    if (!(Test-Path $ProjectRoot)) {
        New-Item -ItemType Directory -Path $ProjectRoot -Force | Out-Null
    }
    
    Set-Location $ProjectRoot
    
    # Initialize pnpm workspace
    Write-BushidoStatus "Setting up pnpm workspace..." "Info"
    pnpm init -y | Out-Null
    
    # Create pnpm-workspace.yaml
    $workspaceContent = @"
packages:
  - 'contracts'
  - 'frontend'
  - 'backend'
  - 'scripts'
"@
    New-BushidoFile -Path "pnpm-workspace.yaml" -Content $workspaceContent
    
    # Create root package.json with scripts
    $rootPackageJson = @"
{
  "name": "bushido-nft",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "pnpm --parallel run dev",
    "build": "pnpm run build:contracts && pnpm --parallel run build",
    "build:contracts": "pnpm --filter contracts run build",
    "test": "pnpm --parallel run test",
    "deploy": "pnpm --filter scripts run deploy",
    "deploy:testnet": "pnpm --filter scripts run deploy:testnet",
    "clean": "pnpm --parallel run clean && rimraf node_modules",
    "format": "prettier --write '**/*.{js,jsx,ts,tsx,json,sol}'",
    "lint": "pnpm --parallel run lint"
  },
  "devDependencies": {
    "prettier": "^3.2.5",
    "rimraf": "^5.0.5",
    "turbo": "^1.12.4"
  },
  "engines": {
    "node": ">=18.0.0",
    "pnpm": ">=8.0.0"
  }
}
"@
    New-BushidoFile -Path "package.json" -Content $rootPackageJson -Force
    
    # Create .gitignore
    $gitignoreContent = @"
# Dependencies
node_modules/
.pnp.*
.yarn/*

# Production
build/
dist/
out/
.next/
.nuxt/
.cache/

# Environment
.env
.env.local
.env.*.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
pnpm-debug.log*

# Editor
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Testing
coverage/
.nyc_output/

# Contracts
artifacts/
cache/
typechain-types/
deployments/localhost/

# Misc
*.pem
.vercel
.turbo
"@
    New-BushidoFile -Path ".gitignore" -Content $gitignoreContent
    
    # Create .prettierrc
    $prettierConfig = @"
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "arrowParens": "always",
  "endOfLine": "lf"
}
"@
    New-BushidoFile -Path ".prettierrc" -Content $prettierConfig
    
    Write-BushidoStatus "Project structure initialized" "Success"
}

function Setup-ContractsPackage {
    Write-BushidoStatus "Setting up smart contracts package..." "Special"
    
    $contractsPath = Join-Path $ProjectRoot "contracts"
    New-Item -ItemType Directory -Path $contractsPath -Force | Out-Null
    Set-Location $contractsPath
    
    # Initialize package
    pnpm init -y | Out-Null
    
    # Create package.json
    $contractsPackageJson = @"
{
  "name": "@bushido/contracts",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "compile": "hardhat compile",
    "test": "hardhat test",
    "deploy": "hardhat run scripts/deploy.ts --network abstract",
    "deploy:testnet": "hardhat run scripts/deploy.ts --network abstractTestnet",
    "verify": "hardhat verify",
    "clean": "hardhat clean && rimraf typechain-types"
  },
  "devDependencies": {
    "@nomicfoundation/hardhat-toolbox": "^4.0.0",
    "@openzeppelin/contracts": "^5.0.1",
    "hardhat": "^2.19.4",
    "typescript": "^5.3.3",
    "@types/node": "^20.11.5",
    "ts-node": "^10.9.2",
    "dotenv": "^16.3.1"
  }
}
"@
    New-BushidoFile -Path "package.json" -Content $contractsPackageJson -Force
    
    # Create hardhat.config.ts
    $hardhatConfig = @"
import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import * as dotenv from 'dotenv';

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.20',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    abstractTestnet: {
      url: process.env.ABSTRACT_TESTNET_RPC || '',
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    abstract: {
      url: process.env.ABSTRACT_MAINNET_RPC || '',
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: {
      abstract: process.env.ABSTRACT_EXPLORER_API_KEY || '',
    },
  },
};

export default config;
"@
    New-BushidoFile -Path "hardhat.config.ts" -Content $hardhatConfig
    
    # Create contract directories
    @("contracts", "contracts/interfaces", "contracts/lib", "scripts", "test") | ForEach-Object {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
    
    if (!$SkipDependencies) {
        Write-BushidoStatus "Installing contract dependencies..." "Info" 2
        pnpm install | Out-Null
    }
    
    Set-Location $ProjectRoot
    Write-BushidoStatus "Contracts package setup complete" "Success"
}

function Setup-FrontendPackage {
    Write-BushidoStatus "Setting up frontend package..." "Special"
    
    $frontendPath = Join-Path $ProjectRoot "frontend"
    
    # Create Next.js app using PowerShell-compatible approach
    Set-Location $ProjectRoot
    
    Write-BushidoStatus "Creating Next.js application..." "Info" 2
    $createNextApp = "pnpm create next-app@latest frontend --typescript --tailwind --app --src-dir --import-alias '@/*' --no-git"
    Invoke-Expression $createNextApp | Out-Null
    
    Set-Location $frontendPath
    
    # Create additional directories
    $frontendDirs = @(
        "src/components/countdown",
        "src/components/mint",
        "src/components/episodes",
        "src/components/shared",
        "src/components/three",
        "src/hooks",
        "src/lib/web3",
        "src/lib/voting",
        "src/lib/utils",
        "src/styles",
        "public/videos",
        "public/models",
        "public/images/clans",
        "public/images/backgrounds"
    )
    
    $frontendDirs | ForEach-Object {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
    
    # Update package.json with additional dependencies
    $packageJsonPath = Join-Path $frontendPath "package.json"
    $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
    
    $additionalDeps = @{
        "wagmi" = "^2.5.7"
        "viem" = "^2.7.6"
        "@rainbow-me/rainbowkit" = "^2.0.0"
        "ethers" = "^6.10.0"
        "@react-three/fiber" = "^8.15.12"
        "@react-three/drei" = "^9.96.1"
        "three" = "^0.160.0"
        "framer-motion" = "^11.0.3"
        "lucide-react" = "^0.312.0"
        "@tanstack/react-query" = "^5.17.9"
        "axios" = "^1.6.5"
        "zustand" = "^4.4.7"
    }
    
    foreach ($dep in $additionalDeps.GetEnumerator()) {
        if (!$packageJson.dependencies.PSObject.Properties[$dep.Key]) {
            $packageJson.dependencies | Add-Member -MemberType NoteProperty -Name $dep.Key -Value $dep.Value
        }
    }
    
    $packageJson | ConvertTo-Json -Depth 10 | Set-Content $packageJsonPath -Encoding UTF8
    
    if (!$SkipDependencies) {
        Write-BushidoStatus "Installing frontend dependencies..." "Info" 2
        pnpm install | Out-Null
    }
    
    Set-Location $ProjectRoot
    Write-BushidoStatus "Frontend package setup complete" "Success"
}

function Setup-BackendPackage {
    Write-BushidoStatus "Setting up backend package..." "Special"
    
    $backendPath = Join-Path $ProjectRoot "backend"
    New-Item -ItemType Directory -Path $backendPath -Force | Out-Null
    Set-Location $backendPath
    
    pnpm init -y | Out-Null
    
    # Create package.json
    $backendPackageJson = @"
{
  "name": "@bushido/backend",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "nodemon --exec tsx src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest",
    "lint": "eslint src --ext .ts"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "compression": "^1.7.4",
    "ethers": "^6.10.0",
    "redis": "^4.6.12",
    "ioredis": "^5.3.2",
    "drizzle-orm": "^0.29.3",
    "@vercel/postgres": "^0.5.1",
    "ipfs-http-client": "^60.0.1",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.11.5",
    "@types/cors": "^2.8.17",
    "@types/compression": "^1.7.5",
    "typescript": "^5.3.3",
    "tsx": "^4.7.0",
    "nodemon": "^3.0.2",
    "vitest": "^1.2.0",
    "@typescript-eslint/eslint-plugin": "^6.19.0",
    "@typescript-eslint/parser": "^6.19.0",
    "eslint": "^8.56.0"
  }
}
"@
    New-BushidoFile -Path "package.json" -Content $backendPackageJson -Force
    
    # Create tsconfig.json
    $tsConfig = @"
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "allowJs": true,
    "noEmit": false,
    "isolatedModules": true,
    "allowSyntheticDefaultImports": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "incremental": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
"@
    New-BushidoFile -Path "tsconfig.json" -Content $tsConfig
    
    # Create directory structure
    @("src", "src/routes", "src/services", "src/db", "src/types", "src/middleware") | ForEach-Object {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
    
    if (!$SkipDependencies) {
        Write-BushidoStatus "Installing backend dependencies..." "Info" 2
        pnpm install | Out-Null
    }
    
    Set-Location $ProjectRoot
    Write-BushidoStatus "Backend package setup complete" "Success"
}

function Setup-ScriptsPackage {
    Write-BushidoStatus "Setting up scripts package..." "Special"
    
    $scriptsPath = Join-Path $ProjectRoot "scripts"
    New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null
    Set-Location $scriptsPath
    
    pnpm init -y | Out-Null
    
    # Create package.json
    $scriptsPackageJson = @"
{
  "name": "@bushido/scripts",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "deploy": "tsx deploy.ts",
    "deploy:testnet": "cross-env NETWORK=testnet tsx deploy.ts",
    "generate-metadata": "tsx generate-metadata.ts",
    "upload-ipfs": "tsx upload-to-ipfs.ts",
    "verify": "tsx verify-contract.ts"
  },
  "dependencies": {
    "ethers": "^6.10.0",
    "hardhat": "^2.19.4",
    "ipfs-http-client": "^60.0.1",
    "pinata-sdk": "^2.1.0",
    "dotenv": "^16.3.1",
    "chalk": "^5.3.0",
    "ora": "^8.0.1"
  },
  "devDependencies": {
    "@types/node": "^20.11.5",
    "typescript": "^5.3.3",
    "tsx": "^4.7.0",
    "cross-env": "^7.0.3"
  }
}
"@
    New-BushidoFile -Path "package.json" -Content $scriptsPackageJson -Force
    
    if (!$SkipDependencies) {
        Write-BushidoStatus "Installing scripts dependencies..." "Info" 2
        pnpm install | Out-Null
    }
    
    Set-Location $ProjectRoot
    Write-BushidoStatus "Scripts package setup complete" "Success"
}

function Create-EnvironmentFiles {
    Write-BushidoStatus "Creating environment configuration files..." "Special"
    
    # Root .env.example
    $envExample = @"
# Abstract Network Configuration
ABSTRACT_MAINNET_RPC=https://mainnet.abstract.io
ABSTRACT_TESTNET_RPC=https://testnet.abstract.io
ABSTRACT_EXPLORER_API_KEY=

# Deployment
PRIVATE_KEY=
CONTRACT_ADDRESS=

# IPFS Configuration
PINATA_API_KEY=
PINATA_SECRET_KEY=
METADATA_BASE_URI=

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/bushido
REDIS_URL=redis://localhost:6379

# Frontend Configuration
NEXT_PUBLIC_CONTRACT_ADDRESS=
NEXT_PUBLIC_CHAIN_ID=
NEXT_PUBLIC_ALCHEMY_KEY=
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=

# Backend Configuration
PORT=3001
NODE_ENV=development

# Video CDN
VIDEO_CDN_URL=
CLOUDFLARE_ACCOUNT_ID=
CLOUDFLARE_API_TOKEN=
"@
    New-BushidoFile -Path ".env.example" -Content $envExample
    
    # Create README files for each package
    $contractsReadme = @"
# Bushido Smart Contracts

## Overview
ERC-721 NFT contract with integrated voting mechanics for the Bushido interactive anime series.

## Key Features
- 1,600 unique NFTs across 8 clans
- Rarity-based voting power system
- Gas-optimized for Abstract L2

## Deployment
\`\`\`bash
pnpm deploy:testnet  # Deploy to testnet
pnpm deploy         # Deploy to mainnet
\`\`\`

## Testing
\`\`\`bash
pnpm test
\`\`\`
"@
    New-BushidoFile -Path "contracts/README.md" -Content $contractsReadme
    
    Write-BushidoStatus "Environment files created" "Success"
}

function Create-VSCodeConfiguration {
    Write-BushidoStatus "Creating VS Code configuration..." "Info"
    
    $vscodePath = Join-Path $ProjectRoot ".vscode"
    New-Item -ItemType Directory -Path $vscodePath -Force | Out-Null
    
    # VS Code settings
    $vscodeSettings = @"
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "solidity.compileUsingRemoteVersion": "v0.8.20+commit.a1b79de6",
  "[solidity]": {
    "editor.defaultFormatter": "JuanBlanco.solidity"
  },
  "files.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.next": true,
    "**/out": true,
    "**/artifacts": true,
    "**/cache": true,
    "**/typechain-types": true
  }
}
"@
    New-BushidoFile -Path ".vscode/settings.json" -Content $vscodeSettings
    
    # VS Code extensions recommendations
    $vscodeExtensions = @"
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "JuanBlanco.solidity",
    "bradlc.vscode-tailwindcss",
    "dsznajder.es7-react-js-snippets",
    "ms-vscode.vscode-typescript-next",
    "christian-kohler.path-intellisense",
    "formulahendry.auto-rename-tag",
    "streetsidesoftware.code-spell-checker"
  ]
}
"@
    New-BushidoFile -Path ".vscode/extensions.json" -Content $vscodeExtensions
    
    Write-BushidoStatus "VS Code configuration created" "Success"
}

# Main execution
try {
    Write-Host "`n" -NoNewline
    Write-Host "🔥 " -ForegroundColor Red -NoNewline
    Write-Host "BUSHIDO NFT PROJECT SETUP" -ForegroundColor White -NoNewline
    Write-Host " 🔥" -ForegroundColor Red
    Write-Host "═" * 50 -ForegroundColor DarkRed
    Write-Host ""
    
    # Check prerequisites
    $requiredCommands = @("node", "pnpm", "git")
    $missingCommands = $requiredCommands | Where-Object { !(Get-Command $_ -ErrorAction SilentlyContinue) }
    
    if ($missingCommands) {
        Write-BushidoStatus "Missing required tools: $($missingCommands -join ', ')" "Error"
        Write-BushidoStatus "Please run setup-prerequisites.ps1 first" "Warning"
        exit 1
    }
    
    # Setup project
    Initialize-ProjectStructure
    Setup-ContractsPackage
    Setup-FrontendPackage
    Setup-BackendPackage
    Setup-ScriptsPackage
    Create-EnvironmentFiles
    Create-VSCodeConfiguration
    
    # Final setup
    Set-Location $ProjectRoot
    
    if (!$SkipDependencies) {
        Write-BushidoStatus "Installing root dependencies..." "Info"
        pnpm install | Out-Null
    }
    
    # Create initial commit
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-BushidoStatus "Initializing Git repository..." "Info"
        git init | Out-Null
        git add . | Out-Null
        git commit -m "Initial commit: Bushido NFT project structure" | Out-Null
        Write-BushidoStatus "Git repository initialized" "Success"
    }
    
    Write-Host "`n" -NoNewline
    Write-Host "═" * 50 -ForegroundColor DarkRed
    Write-Host "✅ " -ForegroundColor Green -NoNewline
    Write-Host "BUSHIDO NFT PROJECT SETUP COMPLETE!" -ForegroundColor White
    Write-Host "═" * 50 -ForegroundColor DarkRed
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Copy .env.example to .env and configure" -ForegroundColor White
    Write-Host "  2. Run 'pnpm dev' to start development servers" -ForegroundColor White
    Write-Host "  3. Deploy contracts: 'pnpm deploy:testnet'" -ForegroundColor White
    Write-Host "`nProject location: " -ForegroundColor Cyan -NoNewline
    Write-Host $ProjectRoot -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-BushidoStatus "Setup failed: $_" "Error"
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    exit 1
}