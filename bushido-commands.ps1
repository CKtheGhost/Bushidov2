# bushido-commands.ps1
# Bushido NFT Development Commands for PowerShell

function Start-BushidoDev {
    Write-Host "🚀 Starting Bushido development servers..." -ForegroundColor Cyan
    Set-Location "C:\Users\$env:USERNAME\bushido-nft"
    pnpm dev
}

function Deploy-BushidoTestnet {
    Write-Host "🔗 Deploying to Abstract testnet..." -ForegroundColor Yellow
    Set-Location "C:\Users\$env:USERNAME\bushido-nft"
    pnpm deploy:testnet
}

function Build-BushidoProject {
    Write-Host "🏗️ Building Bushido project..." -ForegroundColor Green
    Set-Location "C:\Users\$env:USERNAME\bushido-nft"
    pnpm build
}

function Test-BushidoContracts {
    Write-Host "🧪 Testing smart contracts..." -ForegroundColor Magenta
    Set-Location "C:\Users\$env:USERNAME\bushido-nft\contracts"
    pnpm test
}

# Create aliases for quick access
Set-Alias -Name bushido-dev -Value Start-BushidoDev
Set-Alias -Name bushido-deploy -Value Deploy-BushidoTestnet
Set-Alias -Name bushido-build -Value Build-BushidoProject
Set-Alias -Name bushido-test -Value Test-BushidoContracts

Write-Host @"
🔥 Bushido NFT PowerShell Commands Loaded! 🔥

Available commands:
  bushido-dev     - Start development servers
  bushido-deploy  - Deploy to testnet
  bushido-build   - Build project
  bushido-test    - Run tests

Or use the functions directly:
  Start-BushidoDev
  Deploy-BushidoTestnet
  Build-BushidoProject
  Test-BushidoContracts
"@ -ForegroundColor Cyan