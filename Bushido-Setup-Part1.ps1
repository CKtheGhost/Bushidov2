# Bushido-Setup-Part1.ps1
# Part 1: Prerequisites Check and Project Structure Creation

param(
    [switch]$SkipPrerequisites,
    [string]$ProjectPath = (Get-Location).Path
)

#region Configuration
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Config = @{
    Version = '1.0.0'
    ProjectName = 'bushido-nft'
    RequiredTools = @{
        'node' = @{ MinVersion = '18.0.0'; Cmd = 'node --version'; Pattern = 'v(\d+\.\d+\.\d+)' }
        'pnpm' = @{ MinVersion = '8.0.0'; Cmd = 'pnpm --version'; Pattern = '(\d+\.\d+\.\d+)' }
        'git' = @{ MinVersion = '2.0.0'; Cmd = 'git --version'; Pattern = 'git version (\d+\.\d+\.\d+)' }
    }
}
#endregion

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

function Test-Prerequisites {
    Write-Status "Checking prerequisites..." "Info"
    
    $allGood = $true
    
    foreach ($tool in $script:Config.RequiredTools.GetEnumerator()) {
        try {
            $output = Invoke-Expression $tool.Value.Cmd 2>$null
            if ($output -match $tool.Value.Pattern) {
                $version = [version]$matches[1]
                $minVersion = [version]$tool.Value.MinVersion
                
                if ($version -ge $minVersion) {
                    Write-Status "$($tool.Key) $version ✓" "Success"
                } else {
                    Write-Status "$($tool.Key) $version (requires $minVersion+)" "Error"
                    $allGood = $false
                }
            }
        }
        catch {
            Write-Status "$($tool.Key) not found" "Error"
            $allGood = $false
        }
    }
    
    return $allGood
}

function Initialize-ProjectStructure {
    Write-Status "Creating project structure..." "Info"
    
    # Root directories
    $directories = @(
        'contracts',
        'contracts/contracts',
        'contracts/scripts',
        'contracts/test',
        'contracts/interfaces',
        'contracts/libraries',
        'frontend',
        'frontend/src',
        'frontend/src/app',
        'frontend/src/components',
        'frontend/src/hooks',
        'frontend/src/lib',
        'frontend/public',
        'backend',
        'backend/src',
        'backend/src/routes',
        'backend/src/services',
        'scripts',
        'scripts/src',
        'metadata',
        'metadata/clans',
        'docs'
    )
    
    foreach ($dir in $directories) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    Write-Status "Project structure created" "Success"
}

function Create-RootPackageJson {
    Write-Status "Creating root package.json..." "Info"
    
    $package = @{
        name = $script:Config.ProjectName
        version = "1.0.0"
        private = $true
        type = "module"
        description = "Interactive NFT project with episodic anime storytelling"
        scripts = @{
            "dev" = "turbo run dev --parallel"
            "build" = "turbo run build"
            "test" = "turbo run test"
            "deploy:testnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstractTestnet"
            "deploy:mainnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstract"
            "launch:stealth" = "pnpm run build --filter=@bushido/frontend && vercel --prod"
        }
        devDependencies = @{
            "turbo" = "latest"
            "prettier" = "^3.2.5"
            "eslint" = "^8.56.0"
        }
    }
    
    $package | ConvertTo-Json -Depth 10 | Set-Content "package.json" -Encoding UTF8
    Write-Status "Root package.json created" "Success"
}

function Create-WorkspaceConfig {
    Write-Status "Creating workspace configuration..." "Info"
    
    # pnpm-workspace.yaml
    $workspace = @"
packages:
  - 'contracts'
  - 'frontend'
  - 'backend'
  - 'scripts'
"@
    
    Set-Content "pnpm-workspace.yaml" -Value $workspace -Encoding UTF8
    
    # turbo.json
    $turbo = @{
        '$schema' = "https://turbo.build/schema.json"
        pipeline = @{
            "build" = @{
                dependsOn = @("^build")
                outputs = @("dist/**", ".next/**", "artifacts/**")
            }
            "dev" = @{
                cache = $false
                persistent = $true
            }
            "test" = @{
                dependsOn = @("build")
            }
            "deploy" = @{
                dependsOn = @("build")
            }
        }
    }
    
    $turbo | ConvertTo-Json -Depth 10 | Set-Content "turbo.json" -Encoding UTF8
    Write-Status "Workspace configuration created" "Success"
}
#endregion

#region Main Execution
try {
    Write-Host "`n🏯 Bushido NFT Setup - Part 1" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor DarkRed
    
    # Check prerequisites
    if (-not $SkipPrerequisites) {
        if (-not (Test-Prerequisites)) {
            Write-Status "Please install missing prerequisites and run again" "Error"
            exit 1
        }
    }
    
    # Change to project directory
    if ($ProjectPath -ne (Get-Location).Path) {
        Set-Location $ProjectPath
    }
    
    # Create structure
    Initialize-ProjectStructure
    Create-RootPackageJson
    Create-WorkspaceConfig
    
    Write-Host "`n✨ Part 1 Complete!" -ForegroundColor Green
    Write-Host "Run Part 2 to set up contracts package`n" -ForegroundColor Yellow
    
} catch {
    Write-Status "Setup failed: $_" "Error"
    exit 1
}
#endregion