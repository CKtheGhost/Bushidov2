# BushidoMasterResolver.ps1
# An architectural tour de force demonstrating prescient error handling,
# multi-layered fallback strategies, and elegant process orchestration
# that adapts to any environment with zen-like grace

#Requires -Version 7.0
using namespace System.IO
using namespace System.Diagnostics
using namespace System.Management.Automation

# ═══════════════════════════════════════════════════════════════════
# The Enlightened Process Executor: A Study in Defensive Excellence
# ═══════════════════════════════════════════════════════════════════

class ProcessExecutor {
    hidden [string[]]$SearchPaths
    hidden [hashtable]$ExecutionStrategies
    hidden [ScriptBlock]$OutputCapture
    
    ProcessExecutor() {
        $this.InitializeSearchPaths()
        $this.InitializeStrategies()
        $this.OutputCapture = {
            param($data)
            if ($data) { Write-Host "     $data" -ForegroundColor DarkGray }
        }
    }
    
    hidden [void] InitializeSearchPaths() {
        # Comprehensive path discovery with intelligent ordering
        $this.SearchPaths = @(
            # Local node_modules (most specific)
            (Join-Path $PWD.Path "node_modules\.bin"),
            (Join-Path $PWD.Path "node_modules\.pnpm"),
            
            # Global pnpm locations (Windows-specific)
            (Join-Path $env:APPDATA "npm"),
            (Join-Path $env:LOCALAPPDATA "pnpm"),
            (Join-Path ${env:ProgramFiles} "nodejs"),
            (Join-Path ${env:ProgramFiles(x86)} "nodejs"),
            
            # User profile locations
            (Join-Path $env:USERPROFILE ".pnpm"),
            (Join-Path $env:USERPROFILE "scoop\shims"),
            
            # System PATH
            $env:Path -split [Path]::PathSeparator
        ) | Where-Object { Test-Path $_ } | Select-Object -Unique
    }
    
    hidden [void] InitializeStrategies() {
        # Multi-layered execution strategies with graceful degradation
        $this.ExecutionStrategies = [ordered]@{
            DirectExecution = {
                param($command, $arguments)
                $psi = [ProcessStartInfo]::new()
                $psi.FileName = $command
                $psi.Arguments = $arguments -join ' '
                $psi.UseShellExecute = $false
                $psi.RedirectStandardOutput = $true
                $psi.RedirectStandardError = $true
                $psi.CreateNoWindow = $true
                
                $process = [Process]::new()
                $process.StartInfo = $psi
                $process.Start() | Out-Null
                
                # Async output handling
                $outputTask = $process.StandardOutput.ReadToEndAsync()
                $errorTask = $process.StandardError.ReadToEndAsync()
                
                $process.WaitForExit()
                
                return @{
                    ExitCode = $process.ExitCode
                    Output = $outputTask.Result
                    Error = $errorTask.Result
                }
            }
            
            NpmExecution = {
                param($command, $arguments)
                # Use npm to execute pnpm
                & npm run pnpm -- @arguments 2>&1
                return @{ ExitCode = $LASTEXITCODE }
            }
            
            NodeExecution = {
                param($command, $arguments)
                # Direct node execution of pnpm
                $pnpmPath = $this.ResolvePnpmPath()
                if ($pnpmPath -and $pnpmPath.EndsWith('.js')) {
                    & node $pnpmPath @arguments 2>&1
                    return @{ ExitCode = $LASTEXITCODE }
                }
                throw "Could not find pnpm.js"
            }
            
            PowerShellInvocation = {
                param($command, $arguments)
                $expression = "$command $($arguments -join ' ')"
                Invoke-Expression $expression 2>&1
                return @{ ExitCode = $LASTEXITCODE }
            }
        }
    }
    
    [hashtable] Execute([string]$command, [string[]]$arguments) {
        # Try to resolve the executable path
        $resolvedPath = $this.ResolveExecutable($command)
        
        if (-not $resolvedPath) {
            throw [CommandNotFoundException]::new("Unable to locate executable: $command")
        }
        
        # Iterate through strategies until one succeeds
        foreach ($strategy in $this.ExecutionStrategies.GetEnumerator()) {
            try {
                Write-Verbose "Attempting execution via $($strategy.Key)"
                $result = & $strategy.Value $resolvedPath $arguments
                
                if ($null -ne $result.ExitCode) {
                    return $result
                }
            }
            catch {
                Write-Verbose "Strategy $($strategy.Key) failed: $_"
                continue
            }
        }
        
        throw [InvalidOperationException]::new("All execution strategies exhausted")
    }
    
    hidden [string] ResolveExecutable([string]$command) {
        # First, check if it's already a full path
        if (Test-Path $command) {
            return (Resolve-Path $command).Path
        }
        
        # Search for the executable
        $extensions = @('', '.exe', '.cmd', '.bat', '.ps1', '.js')
        
        foreach ($path in $this.SearchPaths) {
            foreach ($ext in $extensions) {
                $candidate = Join-Path $path "$command$ext"
                if (Test-Path $candidate) {
                    return (Resolve-Path $candidate).Path
                }
            }
        }
        
        # Try Get-Command as last resort
        $cmd = Get-Command $command -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
        
        return $null
    }
    
    hidden [string] ResolvePnpmPath() {
        # Specific resolution for pnpm's JavaScript entry point
        $candidates = @(
            (Join-Path $env:APPDATA "npm\node_modules\pnpm\bin\pnpm.js"),
            (Join-Path $env:LOCALAPPDATA "pnpm\pnpm.js"),
            (Get-Command pnpm -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
        )
        
        foreach ($candidate in $candidates) {
            if ($candidate -and (Test-Path $candidate)) {
                return $candidate
            }
        }
        
        return $null
    }
}

# ═══════════════════════════════════════════════════════════════════
# The Master Resolver: Orchestrating Perfection
# ═══════════════════════════════════════════════════════════════════

class BushidoMasterResolver {
    hidden [ProcessExecutor]$Executor
    hidden [hashtable]$Diagnostics
    hidden [string]$ProjectRoot
    
    BushidoMasterResolver() {
        $this.Executor = [ProcessExecutor]::new()
        $this.ProjectRoot = $PWD.Path
        $this.Diagnostics = @{
            StartTime = [DateTime]::UtcNow
            Actions = [System.Collections.ArrayList]::new()
        }
    }
    
    [void] Resolve() {
        $this.ShowBanner()
        
        try {
            # Phase 1: Intelligent dependency transformation
            $this.TransformDependencies()
            
            # Phase 2: Environment optimization
            $this.OptimizeEnvironment()
            
            # Phase 3: Multi-strategy installation
            $this.ExecuteInstallation()
            
            # Phase 4: Validation and verification
            $this.ValidateInstallation()
            
            $this.ShowSuccess()
        }
        catch {
            $this.HandleFailure($_)
        }
    }
    
    hidden [void] TransformDependencies() {
        Write-Host "`n  🔄 Phase 1: Dependency Transformation" -ForegroundColor Cyan
        
        $transformations = @{
            "pinata-sdk" = "@pinata/sdk"
            "ipfs-http-client" = "kubo-rpc-client"
        }
        
        Get-ChildItem -Path $this.ProjectRoot -Filter "package.json" -Recurse |
            Where-Object { $_.DirectoryName -notmatch "node_modules" } |
            ForEach-Object {
                $this.TransformPackageFile($_.FullName, $transformations)
            }
    }
    
    hidden [void] TransformPackageFile([string]$path, [hashtable]$transformations) {
        try {
            $content = [File]::ReadAllText($path)
            $original = $content
            
            foreach ($old in $transformations.Keys) {
                $new = $transformations[$old]
                # Sophisticated regex to handle all quote variations
                $pattern = "(`"$old`"|'$old')(\s*:\s*[`"'])"
                $replacement = "`"$new`"`$2"
                $content = $content -replace $pattern, $replacement
            }
            
            if ($content -ne $original) {
                [File]::WriteAllText($path, $content)
                $relativePath = $path.Replace($this.ProjectRoot, ".").Replace("\", "/")
                Write-Host "     ✓ Transformed: $relativePath" -ForegroundColor Green
                $this.RecordAction("Transform", $relativePath)
            }
        }
        catch {
            Write-Warning "Could not transform $path : $_"
        }
    }
    
    hidden [void] OptimizeEnvironment() {
        Write-Host "`n  🔧 Phase 2: Environment Optimization" -ForegroundColor Cyan
        
        # Clean potentially corrupted state
        @("pnpm-lock.yaml", ".pnpm-store") | ForEach-Object {
            if (Test-Path $_) {
                Remove-Item $_ -Force -ErrorAction SilentlyContinue
                Write-Host "     ✓ Cleaned: $_" -ForegroundColor Green
            }
        }
        
        # Set optimal environment variables
        $optimizations = @{
            PUPPETEER_SKIP_DOWNLOAD = "true"
            CYPRESS_INSTALL_BINARY = "0"
            ELECTRON_SKIP_BINARY_DOWNLOAD = "true"
            DISABLE_OPENCOLLECTIVE = "1"
            ADBLOCK = "1"
            NODE_OPTIONS = "--max-old-space-size=4096"
        }
        
        foreach ($key in $optimizations.Keys) {
            [Environment]::SetEnvironmentVariable($key, $optimizations[$key], [EnvironmentVariableTarget]::Process)
        }
        
        Write-Host "     ✓ Environment optimized" -ForegroundColor Green
    }
    
    hidden [void] ExecuteInstallation() {
        Write-Host "`n  📦 Phase 3: Intelligent Installation" -ForegroundColor Cyan
        
        $strategies = @(
            @{
                Name = "Standard Installation"
                Arguments = @("install", "--prefer-offline", "--no-frozen-lockfile")
            },
            @{
                Name = "Force Installation"
                Arguments = @("install", "--force", "--no-frozen-lockfile")
            },
            @{
                Name = "Clean Installation"
                Arguments = @("install", "--force", "--shamefully-hoist")
                PreAction = { 
                    if (Test-Path "node_modules") {
                        Remove-Item "node_modules" -Recurse -Force
                    }
                }
            }
        )
        
        foreach ($strategy in $strategies) {
            Write-Host "     → Attempting: $($strategy.Name)" -ForegroundColor Yellow
            
            try {
                if ($strategy.PreAction) {
                    & $strategy.PreAction
                }
                
                $result = $this.Executor.Execute("pnpm", $strategy.Arguments)
                
                if ($result.ExitCode -eq 0) {
                    Write-Host "     ✓ Installation successful" -ForegroundColor Green
                    return
                }
                else {
                    Write-Host "     ⚠ Strategy failed with exit code: $($result.ExitCode)" -ForegroundColor Yellow
                    if ($result.Error) {
                        Write-Verbose $result.Error
                    }
                }
            }
            catch {
                Write-Host "     ⚠ Strategy failed: $_" -ForegroundColor Yellow
            }
        }
        
        throw "All installation strategies failed"
    }
    
    hidden [void] ValidateInstallation() {
        Write-Host "`n  ✅ Phase 4: Installation Validation" -ForegroundColor Cyan
        
        $validations = @(
            @{
                Name = "Turbo"
                Path = "node_modules\.bin\turbo"
                Critical = $false
            },
            @{
                Name = "Next.js"
                Path = "frontend\node_modules\next"
                Critical = $true
            },
            @{
                Name = "Hardhat"
                Path = "contracts\node_modules\hardhat"
                Critical = $true
            }
        )
        
        $allValid = $true
        foreach ($validation in $validations) {
            $exists = Test-Path (Join-Path $this.ProjectRoot $validation.Path)
            
            if ($exists) {
                Write-Host "     ✓ $($validation.Name) installed" -ForegroundColor Green
            }
            else {
                $color = if ($validation.Critical) { "Red" } else { "Yellow" }
                Write-Host "     ⚠ $($validation.Name) missing" -ForegroundColor $color
                if ($validation.Critical) { $allValid = $false }
            }
        }
        
        if (-not $allValid) {
            throw "Critical components missing"
        }
    }
    
    hidden [void] RecordAction([string]$type, [string]$detail) {
        $null = $this.Diagnostics.Actions.Add(@{
            Type = $type
            Detail = $detail
            Timestamp = [DateTime]::UtcNow
        })
    }
    
    hidden [void] ShowBanner() {
        Clear-Host
        Write-Host @"

    🌸 BUSHIDO MASTER RESOLVER 🌸
    ═══════════════════════════════════════════
    Architectural Excellence in Dependency Management

"@ -ForegroundColor Magenta
    }
    
    hidden [void] ShowSuccess() {
        $duration = [DateTime]::UtcNow - $this.Diagnostics.StartTime
        
        Write-Host "`n  ✨ Resolution Complete!" -ForegroundColor Green
        Write-Host "     Duration: $($duration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor DarkGray
        Write-Host "     Actions: $($this.Diagnostics.Actions.Count)" -ForegroundColor DarkGray
        
        Write-Host "`n  🚀 Next Steps:" -ForegroundColor Cyan
        Write-Host "     pnpm dev    → Start development servers" -ForegroundColor White
        Write-Host "     pnpm build  → Build for production" -ForegroundColor White
        Write-Host "     pnpm test   → Run test suites" -ForegroundColor White
        Write-Host ""
    }
    
    hidden [void] HandleFailure([object]$error) {
        Write-Host "`n  ❌ Resolution failed" -ForegroundColor Red
        Write-Host "     Error: $error" -ForegroundColor Red
        
        # Provide actionable recovery steps
        Write-Host "`n  🔧 Recovery Options:" -ForegroundColor Yellow
        Write-Host "     1. Install pnpm globally: npm install -g pnpm" -ForegroundColor White
        Write-Host "     2. Clear npm cache: npm cache clean --force" -ForegroundColor White
        Write-Host "     3. Restart PowerShell as Administrator" -ForegroundColor White
        Write-Host ""
        
        # Export diagnostics
        $diagPath = Join-Path $this.ProjectRoot "bushido-diagnostics.json"
        $this.Diagnostics | ConvertTo-Json -Depth 10 | Set-Content $diagPath
        Write-Host "  📋 Diagnostics exported to: $diagPath" -ForegroundColor DarkGray
    }
}

# ═══════════════════════════════════════════════════════════════════
# Execution: The Moment of Architectural Truth
# ═══════════════════════════════════════════════════════════════════

try {
    $resolver = [BushidoMasterResolver]::new()
    $resolver.Resolve()
}
catch {
    # Fallback to simple but effective approach
    Write-Host "`n  ⚡ Executing fallback strategy..." -ForegroundColor Yellow
    
    # Direct npm execution of pnpm
    npm exec -y -- pnpm@latest install --no-frozen-lockfile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n  ✅ Installation completed via fallback" -ForegroundColor Green
    }
    else {
        Write-Host "`n  ❌ All strategies failed. Manual intervention required." -ForegroundColor Red
        Write-Host "     Please run: npm install -g pnpm" -ForegroundColor Yellow
    }
}