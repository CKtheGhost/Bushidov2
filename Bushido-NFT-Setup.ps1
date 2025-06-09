# Bushido-NFT-Setup.ps1
# Orchestration script for Bushido NFT project initialization
# Designed for PowerShell 7.0+ with enterprise patterns

#Requires -Version 7.0

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = (Get-Location).Path,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPrerequisites,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose,
    
    [Parameter(Mandatory=$false)]
    [switch]$MinimalSetup
)

# Set verbose preference if requested
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# ═══════════════════════════════════════════════════════════════════
# Configuration & Constants
# ═══════════════════════════════════════════════════════════════════

$script:Config = @{
    ProjectName = "bushido-nft"
    RequiredTools = @{
        "node" = @{
            MinVersion = "18.0.0"
            InstallCmd = "winget install OpenJS.NodeJS.LTS"
        }
        "pnpm" = @{
            MinVersion = "8.0.0"
            InstallCmd = "npm install -g pnpm"
        }
        "git" = @{
            MinVersion = "2.0.0"
            InstallCmd = "winget install Git.Git"
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════

function Write-BushidoLog {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $colors = @{
        "Info" = "Cyan"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error" = "Red"
        "Debug" = "DarkGray"
    }
    
    $symbols = @{
        "Info" = "ℹ"
        "Success" = "✓"
        "Warning" = "⚠"
        "Error" = "✗"
        "Debug" = "🔍"
    }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($symbols[$Level]) " -NoNewline -ForegroundColor $colors[$Level]
    Write-Host $Message
}

function Test-Prerequisites {
    Write-BushidoLog "Checking prerequisites..." "Info"
    
    $allGood = $true
    
    foreach ($tool in $script:Config.RequiredTools.GetEnumerator()) {
        $cmd = Get-Command $tool.Key -ErrorAction SilentlyContinue
        
        if ($null -eq $cmd) {
            Write-BushidoLog "$($tool.Key) not found. Install with: $($tool.Value.InstallCmd)" "Error"
            $allGood = $false
        } else {
            # Check version if possible
            $version = & $tool.Key --version 2>&1
            Write-BushidoLog "$($tool.Key) found: $version" "Success"
        }
    }
    
    return $allGood
}

function Initialize-Workspace {
    Write-BushidoLog "Initializing Bushido NFT workspace..." "Info"
    
    # Create root package.json
    $rootPackageJson = @{
        name = "bushido-nft"
        version = "1.0.0"
        private = $true
        type = "module"
        scripts = @{
            "dev" = "turbo run dev --parallel"
            "build" = "turbo run build"
            "test" = "turbo run test"
            "lint" = "turbo run lint"
            "format" = "prettier --write '**/*.{js,jsx,ts,tsx,json,sol,md}'"
            "clean" = "turbo run clean && rimraf node_modules"
        }
        devDependencies = @{
            "turbo" = "^1.12.4"
            "prettier" = "^3.2.5"
            "eslint" = "^8.56.0"
            "rimraf" = "^5.0.5"
        }
    } | ConvertTo-Json -Depth 10
    
    Set-Content -Path "package.json" -Value $rootPackageJson -Encoding UTF8
    
    # Create pnpm workspace
    $workspaceYaml = @"
packages:
  - 'contracts'
  - 'frontend'
  - 'backend'
  - 'scripts'
"@
    Set-Content -Path "pnpm-workspace.yaml" -Value $workspaceYaml -Encoding UTF8
    
    # Create turbo.json
    $turboJson = @{
        '$schema' = "https://turbo.build/schema.json"
        pipeline = @{
            build = @{
                dependsOn = @("^build")
                outputs = @("dist/**", ".next/**", "artifacts/**")
            }
            dev = @{
                cache = $false
                persistent = $true
            }
            test = @{
                dependsOn = @("build")
            }
            lint = @{
                outputs = @()
            }
        }
    } | ConvertTo-Json -Depth 10
    
    Set-Content -Path "turbo.json" -Value $turboJson -Encoding UTF8
    
    Write-BushidoLog "Workspace configuration created" "Success"
}

function Initialize-ContractsPackage {
    Write-BushidoLog "Setting up smart contracts package..." "Info"
    
    $contractsPath = "contracts"
    New-Item -ItemType Directory -Path $contractsPath -Force | Out-Null
    
    Push-Location $contractsPath
    try {
        # Package.json for contracts
        $packageJson = @{
            name = "@bushido/contracts"
            version = "1.0.0"
            private = $true
            type = "module"
            scripts = @{
                "compile" = "hardhat compile"
                "test" = "hardhat test"
                "deploy" = "hardhat run scripts/deploy.ts"
                "clean" = "hardhat clean && rimraf artifacts cache"
            }
            devDependencies = @{
                "hardhat" = "^2.19.4"
                "@nomicfoundation/hardhat-toolbox" = "^4.0.0"
                "@openzeppelin/contracts" = "^5.0.1"
                "typescript" = "^5.3.3"
                "dotenv" = "^16.3.1"
            }
        } | ConvertTo-Json -Depth 10
        
        Set-Content -Path "package.json" -Value $packageJson -Encoding UTF8
        
        # Create directory structure
        @("contracts", "scripts", "test") | ForEach-Object {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
        
        Write-BushidoLog "Contracts package initialized" "Success"
    }
    finally {
        Pop-Location
    }
}

function Initialize-FrontendPackage {
    Write-BushidoLog "Creating Next.js frontend..." "Info"
    
    if (-not $MinimalSetup) {
        # Full Next.js setup
        $createCmd = "pnpm create next-app@latest frontend --typescript --tailwind --app --src-dir --import-alias '@/*' --no-git --yes"
        Write-BushidoLog "Running: $createCmd" "Debug"
        
        $process = Start-Process -FilePath "pnpm" -ArgumentList "create", "next-app@latest", "frontend", "--typescript", "--tailwind", "--app", "--src-dir", "--import-alias", "@/*", "--no-git", "--yes" -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-BushidoLog "Next.js app created successfully" "Success"
            
            # Add Web3 dependencies
            Push-Location "frontend"
            try {
                pnpm add wagmi viem @rainbow-me/rainbowkit ethers
                pnpm add @react-three/fiber @react-three/drei three framer-motion
                pnpm add lucide-react zustand @tanstack/react-query
                
                Write-BushidoLog "Frontend dependencies installed" "Success"
            }
            finally {
                Pop-Location
            }
        } else {
            Write-BushidoLog "Failed to create Next.js app" "Error"
        }
    } else {
        # Minimal setup - just create structure
        New-Item -ItemType Directory -Path "frontend" -Force | Out-Null
        Push-Location "frontend"
        try {
            $packageJson = @{
                name = "@bushido/frontend"
                version = "1.0.0"
                private = $true
                scripts = @{
                    "dev" = "next dev"
                    "build" = "next build"
                    "start" = "next start"
                }
            } | ConvertTo-Json -Depth 10
            
            Set-Content -Path "package.json" -Value $packageJson -Encoding UTF8
        }
        finally {
            Pop-Location
        }
    }
}

function Initialize-BackendPackage {
    Write-BushidoLog "Setting up backend API..." "Info"
    
    $backendPath = "backend"
    New-Item -ItemType Directory -Path $backendPath -Force | Out-Null
    
    Push-Location $backendPath
    try {
        $packageJson = @{
            name = "@bushido/backend"
            version = "1.0.0"
            private = $true
            type = "module"
            scripts = @{
                "dev" = "nodemon src/index.ts"
                "build" = "tsc"
                "start" = "node dist/index.js"
            }
            dependencies = @{
                "express" = "^4.18.2"
                "cors" = "^2.8.5"
                "ethers" = "^6.10.0"
            }
            devDependencies = @{
                "@types/express" = "^4.17.21"
                "@types/node" = "^20.11.0"
                "typescript" = "^5.3.3"
                "nodemon" = "^3.0.2"
                "ts-node" = "^10.9.2"
            }
        } | ConvertTo-Json -Depth 10
        
        Set-Content -Path "package.json" -Value $packageJson -Encoding UTF8
        
        # Create directory structure
        @("src", "src/routes", "src/services") | ForEach-Object {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
        
        Write-BushidoLog "Backend package initialized" "Success"
    }
    finally {
        Pop-Location
    }
}

function Initialize-ScriptsPackage {
    Write-BushidoLog "Setting up scripts package..." "Info"
    
    $scriptsPath = "scripts"
    New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null
    
    Push-Location $scriptsPath
    try {
        $packageJson = @{
            name = "@bushido/scripts"
            version = "1.0.0"
            private = $true
            type = "module"
            scripts = @{
                "generate-metadata" = "ts-node src/generate-metadata.ts"
                "upload-ipfs" = "ts-node src/upload-ipfs.ts"
            }
            devDependencies = @{
                "typescript" = "^5.3.3"
                "ts-node" = "^10.9.2"
                "ipfs-http-client" = "^60.0.1"
            }
        } | ConvertTo-Json -Depth 10
        
        Set-Content -Path "package.json" -Value $packageJson -Encoding UTF8
        
        New-Item -ItemType Directory -Path "src" -Force | Out-Null
        
        Write-BushidoLog "Scripts package initialized" "Success"
    }
    finally {
        Pop-Location
    }
}

function Create-ConfigurationFiles {
    Write-BushidoLog "Creating configuration files..." "Info"
    
    # .gitignore
    $gitignore = @"
# Dependencies
node_modules/
.pnpm-store/

# Production
build/
dist/
.next/
artifacts/
cache/

# Environment
.env
.env*.local

# Logs
*.log

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
"@
    Set-Content -Path ".gitignore" -Value $gitignore -Encoding UTF8
    
    # .prettierrc
    $prettierrc = @{
        semi = $true
        singleQuote = $true
        trailingComma = "es5"
        printWidth = 100
        tabWidth = 2
    } | ConvertTo-Json
    
    Set-Content -Path ".prettierrc" -Value $prettierrc -Encoding UTF8
    
    # .env.example
    $envExample = @"
# Blockchain
PRIVATE_KEY=your_private_key_here
ABSTRACT_TESTNET_RPC=https://api.testnet.abs.xyz
ABSTRACT_MAINNET_RPC=https://api.abs.xyz

# Frontend
NEXT_PUBLIC_NETWORK=testnet
NEXT_PUBLIC_CONTRACT_ADDRESS=

# IPFS
PINATA_API_KEY=
PINATA_SECRET_KEY=

# Analytics
NEXT_PUBLIC_GA_ID=
"@
    Set-Content -Path ".env.example" -Value $envExample -Encoding UTF8
    
    Write-BushidoLog "Configuration files created" "Success"
}

function Show-Banner {
    Clear-Host
    Write-Host @"

    ██████╗ ██╗   ██╗███████╗██╗  ██╗██╗██████╗  ██████╗ 
    ██╔══██╗██║   ██║██╔════╝██║  ██║██║██╔══██╗██╔═══██╗
    ██████╔╝██║   ██║███████╗███████║██║██║  ██║██║   ██║
    ██╔══██╗██║   ██║╚════██║██╔══██║██║██║  ██║██║   ██║
    ██████╔╝╚██████╔╝███████║██║  ██║██║██████╔╝╚██████╔╝
    ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ 
                                                            
           Interactive NFT Anime • Web3 Storytelling
                    
"@ -ForegroundColor Red
    
    Write-Host "    Stealth Launch Edition | Abstract L2 Ready" -ForegroundColor DarkGray
    Write-Host "    ═══════════════════════════════════════════════════`n" -ForegroundColor DarkRed
}

function Show-CompletionMessage {
    Write-Host "`n    ✨ " -NoNewline -ForegroundColor Magenta
    Write-Host "PROJECT SETUP COMPLETE!" -ForegroundColor White
    Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkGreen
    
    Write-Host "`n    🚀 Quick Start Commands:" -ForegroundColor Cyan
    Write-Host "       pnpm install          " -NoNewline -ForegroundColor White
    Write-Host "# Install all dependencies" -ForegroundColor DarkGray
    Write-Host "       pnpm dev              " -NoNewline -ForegroundColor White
    Write-Host "# Start development servers" -ForegroundColor DarkGray
    Write-Host "       pnpm build            " -NoNewline -ForegroundColor White
    Write-Host "# Build for production" -ForegroundColor DarkGray
    
    Write-Host "`n    📁 Project Structure:" -ForegroundColor Yellow
    Write-Host "       /contracts            " -NoNewline -ForegroundColor White
    Write-Host "# Smart contracts (Hardhat)" -ForegroundColor DarkGray
    Write-Host "       /frontend             " -NoNewline -ForegroundColor White
    Write-Host "# Next.js 14 app" -ForegroundColor DarkGray
    Write-Host "       /backend              " -NoNewline -ForegroundColor White
    Write-Host "# Express API server" -ForegroundColor DarkGray
    Write-Host "       /scripts              " -NoNewline -ForegroundColor White
    Write-Host "# Deployment tools" -ForegroundColor DarkGray
    
    Write-Host "`n    ⚡ Next Steps:" -ForegroundColor Magenta
    Write-Host "       1. Copy .env.example to .env and configure" -ForegroundColor White
    Write-Host "       2. Run 'pnpm install' to install dependencies" -ForegroundColor White
    Write-Host "       3. Start development with 'pnpm dev'`n" -ForegroundColor White
}

# ═══════════════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════════════

try {
    Show-Banner
    
    # Check prerequisites
    if (-not $SkipPrerequisites) {
        if (-not (Test-Prerequisites)) {
            Write-BushidoLog "Please install missing prerequisites and run again" "Error"
            exit 1
        }
    }
    
    # Create project directory if needed
    if ($ProjectPath -ne (Get-Location).Path) {
        New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
        Set-Location $ProjectPath
    }
    
    # Initialize project structure
    Initialize-Workspace
    Initialize-ContractsPackage
    Initialize-FrontendPackage
    Initialize-BackendPackage
    Initialize-ScriptsPackage
    Create-ConfigurationFiles
    
    # Show completion message
    Show-CompletionMessage
    
} catch {
    Write-BushidoLog "Setup failed: $_" "Error"
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    exit 1
}