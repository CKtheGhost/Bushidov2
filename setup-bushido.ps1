# setup-bushido.ps1
# Bushido NFT Complete Project Setup - Streamlined Edition
# For PowerShell 7.5.1+

#Requires -Version 7.0

param(
    [string]$ProjectPath = $PWD.Path,
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

# Elegant console output
function Write-Step {
    param([string]$Message, [string]$Type = "Info")
    $symbols = @{
        "Info" = "→"
        "Success" = "✓"
        "Error" = "✗"
        "Working" = "◆"
    }
    $colors = @{
        "Info" = "Cyan"
        "Success" = "Green"
        "Error" = "Red"
        "Working" = "Yellow"
    }
    Write-Host "  $($symbols[$Type]) " -NoNewline -ForegroundColor $colors[$Type]
    Write-Host $Message
}

# Show banner
Clear-Host
Write-Host @"

    ██████╗ ██╗   ██╗███████╗██╗  ██╗██╗██████╗  ██████╗ 
    ██╔══██╗██║   ██║██╔════╝██║  ██║██║██╔══██╗██╔═══██╗
    ██████╔╝██║   ██║███████╗███████║██║██║  ██║██║   ██║
    ██╔══██╗██║   ██║╚════██║██╔══██║██║██║  ██║██║   ██║
    ██████╔╝╚██████╔╝███████║██║  ██║██║██████╔╝╚██████╔╝
    ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ 

              STEALTH LAUNCH NFT • ABSTRACT L2
"@ -ForegroundColor Red

Write-Host "`n  Creating your Bushido NFT project...`n" -ForegroundColor White

try {
    # Initialize workspace
    Write-Step "Initializing pnpm workspace" "Working"
    pnpm init -y | Out-Null
    
    # Create workspace config
    @"
packages:
  - 'contracts'
  - 'frontend'
  - 'backend'
  - 'scripts'
"@ | Set-Content "pnpm-workspace.yaml" -Encoding UTF8
    
    # Update root package.json
    $rootPackage = @{
        name = "bushido-nft"
        version = "1.0.0"
        private = $true
        scripts = @{
            "dev" = "pnpm --parallel run dev"
            "build" = "pnpm --parallel run build"
            "test" = "pnpm --parallel run test"
            "deploy:testnet" = "pnpm --filter scripts run deploy:testnet"
            "deploy:mainnet" = "pnpm --filter scripts run deploy:mainnet"
        }
        devDependencies = @{
            "prettier" = "^3.2.5"
            "turbo" = "^1.12.4"
        }
    }
    $rootPackage | ConvertTo-Json -Depth 5 | Set-Content "package.json" -Encoding UTF8
    Write-Step "Workspace configured" "Success"
    
    # Create contracts package
    Write-Step "Setting up smart contracts" "Working"
    New-Item -ItemType Directory -Path "contracts" -Force | Out-Null
    Push-Location "contracts"
    
    pnpm init -y | Out-Null
    $contractsPackage = Get-Content "package.json" -Raw | ConvertFrom-Json
    $contractsPackage.name = "@bushido/contracts"
    $contractsPackage.scripts = @{
        "compile" = "hardhat compile"
        "test" = "hardhat test"
        "deploy" = "hardhat run scripts/deploy.ts"
    }
    $contractsPackage | ConvertTo-Json -Depth 5 | Set-Content "package.json" -Encoding UTF8
    
    # Create directories
    @("contracts", "scripts", "test") | ForEach-Object {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
    
    # Create basic hardhat config
    @"
import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';

const config: HardhatUserConfig = {
  solidity: '0.8.20',
  networks: {
    abstractTestnet: {
      url: process.env.ABSTRACT_TESTNET_RPC || '',
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    }
  }
};

export default config;
"@ | Set-Content "hardhat.config.ts" -Encoding UTF8
    
    Pop-Location
    Write-Step "Smart contracts package ready" "Success"
    
    # Create frontend
    Write-Step "Creating Next.js frontend (this takes a moment)" "Working"
    $createNextCommand = "pnpm create next-app@latest frontend --typescript --tailwind --app --src-dir --import-alias '@/*' --no-git --yes"
    Invoke-Expression $createNextCommand *>&1 | Out-Null
    
    Push-Location "frontend"
    
    # Add Web3 dependencies to package.json
    $frontendPackage = Get-Content "package.json" -Raw | ConvertFrom-Json
    $frontendPackage.dependencies | Add-Member -MemberType NoteProperty -Name "wagmi" -Value "^2.5.7" -Force
    $frontendPackage.dependencies | Add-Member -MemberType NoteProperty -Name "viem" -Value "^2.7.6" -Force
    $frontendPackage.dependencies | Add-Member -MemberType NoteProperty -Name "@rainbow-me/rainbowkit" -Value "^2.0.0" -Force
    $frontendPackage.dependencies | Add-Member -MemberType NoteProperty -Name "framer-motion" -Value "^11.0.3" -Force
    $frontendPackage | ConvertTo-Json -Depth 5 | Set-Content "package.json" -Encoding UTF8
    
    Pop-Location
    Write-Step "Frontend package ready" "Success"
    
    # Create backend
    Write-Step "Setting up Express backend" "Working"
    New-Item -ItemType Directory -Path "backend" -Force | Out-Null
    Push-Location "backend"
    
    pnpm init -y | Out-Null
    $backendPackage = @{
        name = "@bushido/backend"
        version = "1.0.0"
        private = $true
        type = "module"
        scripts = @{
            "dev" = "nodemon src/index.js"
            "start" = "node src/index.js"
        }
    }
    $backendPackage | ConvertTo-Json -Depth 5 | Set-Content "package.json" -Encoding UTF8
    
    New-Item -ItemType Directory -Path "src" -Force | Out-Null
    Pop-Location
    Write-Step "Backend package ready" "Success"
    
    # Create scripts
    Write-Step "Setting up deployment scripts" "Working"
    New-Item -ItemType Directory -Path "scripts" -Force | Out-Null
    Push-Location "scripts"
    
    pnpm init -y | Out-Null
    $scriptsPackage = Get-Content "package.json" -Raw | ConvertFrom-Json
    $scriptsPackage.name = "@bushido/scripts"
    $scriptsPackage | ConvertTo-Json -Depth 5 | Set-Content "package.json" -Encoding UTF8
    
    Pop-Location
    Write-Step "Scripts package ready" "Success"
    
    # Create essential files
    Write-Step "Creating configuration files" "Working"
    
    # .gitignore
    @"
node_modules/
.env
.env.local
.next/
dist/
build/
artifacts/
cache/
coverage/
typechain-types/
.DS_Store
*.log
"@ | Set-Content ".gitignore" -Encoding UTF8
    
    # .env.example
    @"
# Network Configuration
ABSTRACT_TESTNET_RPC=https://testnet.abstract.io
ABSTRACT_MAINNET_RPC=https://mainnet.abstract.io
PRIVATE_KEY=your_private_key_here

# Frontend
NEXT_PUBLIC_CONTRACT_ADDRESS=
NEXT_PUBLIC_CHAIN_ID=11124

# IPFS
PINATA_API_KEY=
PINATA_SECRET_KEY=
"@ | Set-Content ".env.example" -Encoding UTF8
    
    Write-Step "Configuration files created" "Success"
    
    # Install dependencies
    if (-not $SkipInstall) {
        Write-Step "Installing dependencies (this will take a few minutes)" "Working"
        pnpm install --recursive
        Write-Step "All dependencies installed" "Success"
    }
    
    # Success message
    Write-Host "`n  ✨ " -NoNewline -ForegroundColor Green
    Write-Host "PROJECT SETUP COMPLETE!" -ForegroundColor White
    Write-Host "  ═══════════════════════════════════════════`n" -ForegroundColor DarkGreen
    
    Write-Host "  📁 Project Structure:" -ForegroundColor Yellow
    Write-Host "     contracts/  - Smart contracts (Hardhat)"
    Write-Host "     frontend/   - Next.js app with Web3"
    Write-Host "     backend/    - Express API server"
    Write-Host "     scripts/    - Deployment tools`n"
    
    Write-Host "  🚀 Next Steps:" -ForegroundColor Cyan
    Write-Host "     1. Copy .env.example to .env"
    Write-Host "     2. Add your private key and RPC URLs"
    Write-Host "     3. Run 'pnpm dev' to start development`n"
    
    Write-Host "  💡 Useful Commands:" -ForegroundColor Magenta
    Write-Host "     pnpm dev              - Start all services"
    Write-Host "     pnpm build            - Build for production"
    Write-Host "     pnpm deploy:testnet   - Deploy to Abstract testnet`n"
    
} catch {
    Write-Step "Setup failed: $_" "Error"
    Write-Host "`n  Check the error above and try again.`n" -ForegroundColor Red
    exit 1
}