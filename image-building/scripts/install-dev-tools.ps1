# Install Additional Development Tools
# This script installs development tools not covered by Chocolatey

Write-Host "Installing additional development tools..." -ForegroundColor Green

try {
    # Install Windows Subsystem for Linux (Ubuntu 24.04)
    Write-Host "Configuring WSL2 for Ubuntu 24.04..." -ForegroundColor Yellow
    try {
        # WSL2 should already be installed and configured by the main Packer script
        # Just verify and configure additional settings
        
        # Set WSL2 as default
        wsl --set-default-version 2
        
        # Configure WSL settings
        $wslConfig = @"
[wsl2]
memory=4GB
processors=2
swap=2GB
localhostForwarding=true

[interop]
enabled=true
appendWindowsPath=true
"@
        
        $wslConfigPath = "$env:USERPROFILE\.wslconfig"
        $wslConfig | Out-File -FilePath $wslConfigPath -Encoding UTF8 -Force
        
        Write-Host "✓ WSL2 configuration updated" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to configure WSL2: $($_.Exception.Message)"
    }

    # Install Azure PowerShell module
    Write-Host "Installing Azure PowerShell module..." -ForegroundColor Yellow
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module -Name Az -Repository PSGallery -Force -AllowClobber -Scope AllUsers
        Write-Host "✓ Azure PowerShell module installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install Azure PowerShell module: $($_.Exception.Message)"
    }

    # Install Python tools and pipx
    Write-Host "Installing Python tools and pipx..." -ForegroundColor Yellow
    try {
        # Install pipx for Python package management
        python -m pip install --user pipx
        python -m pipx ensurepath
        
        # Add pipx to PATH
        $pipxPath = "$env:USERPROFILE\AppData\Roaming\Python\Python311\Scripts"
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$pipxPath*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$pipxPath", "Machine")
        }
        
        # Install common Python development tools via pipx
        & "$pipxPath\pipx.exe" install black
        & "$pipxPath\pipx.exe" install flake8
        & "$pipxPath\pipx.exe" install pytest
        & "$pipxPath\pipx.exe" install poetry
        & "$pipxPath\pipx.exe" install cookiecutter
        & "$pipxPath\pipx.exe" install pre-commit
        
        Write-Host "✓ Python tools and pipx installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install Python tools and pipx: $($_.Exception.Message)"
    }

    # Install .NET SDK (latest LTS)
    Write-Host "Installing .NET SDK..." -ForegroundColor Yellow
    try {
        $dotnetUrl = "https://dotnetcli.azureedge.net/dotnet/Sdk/LTS/dotnet-sdk-win-x64.exe"
        $dotnetPath = "$env:TEMP\dotnet-sdk-installer.exe"
        
        Invoke-WebRequest -Uri $dotnetUrl -OutFile $dotnetPath -UseBasicParsing
        Start-Process -FilePath $dotnetPath -ArgumentList "/quiet" -Wait
        
        Write-Host "✓ .NET SDK installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install .NET SDK: $($_.Exception.Message)"
    }
    Write-Host "Installing OpenJDK 17..." -ForegroundColor Yellow
    try {
        choco install -y openjdk17
        
        # Set JAVA_HOME environment variable
        $javaHome = "C:\Program Files\Eclipse Adoptium\jdk-17.0.8.101-hotspot"
        [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
        
        # Add Java to PATH
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$javaHome\bin*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$javaHome\bin", "Machine")
        }
        
        Write-Host "✓ OpenJDK 17 installed and configured" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install OpenJDK: $($_.Exception.Message)"
    }

    # Install Maven
    Write-Host "Installing Apache Maven..." -ForegroundColor Yellow
    try {
        choco install -y maven
        Write-Host "✓ Apache Maven installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install Maven: $($_.Exception.Message)"
    }

    # Install Gradle
    Write-Host "Installing Gradle..." -ForegroundColor Yellow
    try {
        choco install -y gradle
        Write-Host "✓ Gradle installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install Gradle: $($_.Exception.Message)"
    }

    # Install Redis CLI
    Write-Host "Installing Redis CLI..." -ForegroundColor Yellow
    try {
        choco install -y redis-64
        Write-Host "✓ Redis CLI installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install Redis CLI: $($_.Exception.Message)"
    }

    # Install MongoDB Compass
    Write-Host "Installing MongoDB Compass..." -ForegroundColor Yellow
    try {
        choco install -y mongodb-compass
        Write-Host "✓ MongoDB Compass installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install MongoDB Compass: $($_.Exception.Message)"
    }

    # Install Insomnia (REST client)
    Write-Host "Installing Insomnia..." -ForegroundColor Yellow
    try {
        choco install -y insomnia-rest-api-client
        Write-Host "✓ Insomnia installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install Insomnia: $($_.Exception.Message)"
    }

    # Install DBeaver (Database tool)
    Write-Host "Installing DBeaver..." -ForegroundColor Yellow
    try {
        choco install -y dbeaver
        Write-Host "✓ DBeaver installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install DBeaver: $($_.Exception.Message)"
    }

    # Install Wireshark
    Write-Host "Installing Wireshark..." -ForegroundColor Yellow
    try {
        choco install -y wireshark
        Write-Host "✓ Wireshark installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install Wireshark: $($_.Exception.Message)"
    }

    # Install Fiddler
    Write-Host "Installing Fiddler..." -ForegroundColor Yellow
    try {
        choco install -y fiddler
        Write-Host "✓ Fiddler installed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install Fiddler: $($_.Exception.Message)"
    }

    # Install Windows Terminal (if not already installed)
    Write-Host "Ensuring Windows Terminal is installed..." -ForegroundColor Yellow
    try {
        $terminal = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
        if (-not $terminal) {
            choco install -y microsoft-windows-terminal
            Write-Host "✓ Windows Terminal installed" -ForegroundColor Green
        } else {
            Write-Host "✓ Windows Terminal already installed" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Failed to install Windows Terminal: $($_.Exception.Message)"
    }

    # Configure Windows Terminal
    Write-Host "Configuring Windows Terminal..." -ForegroundColor Yellow
    try {
        $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        $terminalSettingsDir = Split-Path $terminalSettingsPath -Parent
        
        if (Test-Path $terminalSettingsDir) {
            $terminalSettings = @{
                '$schema' = "https://aka.ms/terminal-profiles-schema"
                'defaultProfile' = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
                'copyOnSelect' = $true
                'copyFormatting' = $false
                'profiles' = @{
                    'defaults' = @{
                        'fontFace' = "Cascadia Code"
                        'fontSize' = 10
                        'colorScheme' = "One Half Dark"
                    }
                    'list' = @(
                        @{
                            'guid' = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
                            'name' = "PowerShell"
                            'source' = "Windows.Terminal.PowershellCore"
                            'startingDirectory' = "%USERPROFILE%"
                        },
                        @{
                            'guid' = "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}"
                            'name' = "Command Prompt"
                            'commandline' = "cmd.exe"
                            'startingDirectory' = "%USERPROFILE%"
                        },
                        @{
                            'guid' = "{2c4de342-38b7-51cf-b940-2309a097f518}"
                            'name' = "Ubuntu 24.04"
                            'source' = "Windows.Terminal.Wsl"
                            'commandline' = "wsl.exe -d Ubuntu-24.04"
                            'startingDirectory' = "//wsl$/Ubuntu-24.04/home/developer"
                            'icon' = "ms-appx:///ProfileIcons/{9acb9455-ca41-5af7-950f-6bca1bc9722f}.png"
                        }
                    )
                }
                'schemes' = @(
                    @{
                        'name' = "One Half Dark"
                        'black' = "#282c34"
                        'red' = "#e06c75"
                        'green' = "#98c379"
                        'yellow' = "#e5c07b"
                        'blue' = "#61afef"
                        'purple' = "#c678dd"
                        'cyan' = "#56b6c2"
                        'white' = "#dcdfe4"
                        'brightBlack' = "#5a6374"
                        'brightRed' = "#e06c75"
                        'brightGreen' = "#98c379"
                        'brightYellow' = "#e5c07b"
                        'brightBlue' = "#61afef"
                        'brightPurple' = "#c678dd"
                        'brightCyan' = "#56b6c2"
                        'brightWhite' = "#dcdfe4"
                        'background' = "#282c34"
                        'foreground' = "#dcdfe4"
                    }
                )
                'actions' = @(
                    @{ 'command' = @{ 'action' = "copy"; 'singleLine' = $false }; 'keys' = "ctrl+c" },
                    @{ 'command' = "paste"; 'keys' = "ctrl+v" },
                    @{ 'command' = "find"; 'keys' = "ctrl+shift+f" },
                    @{ 'command' = @{ 'action' = "splitPane"; 'split' = "auto"; 'splitMode' = "duplicate" }; 'keys' = "alt+shift+d" }
                )
            }
            
            $terminalSettingsJson = $terminalSettings | ConvertTo-Json -Depth 10
            $terminalSettingsJson | Out-File -FilePath $terminalSettingsPath -Encoding UTF8 -Force
            Write-Host "✓ Windows Terminal configured" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Failed to configure Windows Terminal: $($_.Exception.Message)"
    }

    # Install Oh My Posh for PowerShell
    Write-Host "Installing Oh My Posh..." -ForegroundColor Yellow
    try {
        choco install -y oh-my-posh
        
        # Configure PowerShell profile
        $profilePath = $PROFILE.AllUsersAllHosts
        $profileDir = Split-Path $profilePath -Parent
        
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force
        }
        
        $profileContent = @"
# Oh My Posh configuration
oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json' | Invoke-Expression

# Import modules
Import-Module Az -Force -ErrorAction SilentlyContinue

# Aliases
Set-Alias -Name k -Value kubectl
Set-Alias -Name tf -Value terraform
Set-Alias -Name g -Value git

# Docker aliases for WSL
function docker { wsl docker `$args }
function docker-compose { wsl docker-compose `$args }

# WSL aliases
function ubuntu { wsl -d Ubuntu-24.04 `$args }
function wsl-docker { wsl docker `$args }

# Functions
function ll { Get-ChildItem -Force }
function la { Get-ChildItem -Force -Hidden }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# Git functions
function gs { git status }
function ga { git add . }
function gc { param([string]`$message) git commit -m `$message }
function gp { git push }
function gl { git pull }

# Development functions
function dev-start { 
    Write-Host "Starting development environment..." -ForegroundColor Green
    Write-Host "WSL Docker: wsl docker --version" -ForegroundColor Yellow
    wsl docker --version
    Write-Host "Node.js: node --version" -ForegroundColor Yellow
    node --version
    Write-Host "Java: java --version" -ForegroundColor Yellow
    java --version
}

Write-Host "PowerShell profile loaded with development tools!" -ForegroundColor Green
Write-Host "Available commands:" -ForegroundColor Cyan
Write-Host "  • docker (via WSL)" -ForegroundColor Cyan
Write-Host "  • ubuntu (WSL Ubuntu 24.04)" -ForegroundColor Cyan
Write-Host "  • dev-start (check dev environment)" -ForegroundColor Cyan
"@
        
        $profileContent | Out-File -FilePath $profilePath -Encoding UTF8 -Force
        Write-Host "✓ Oh My Posh and PowerShell profile configured" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to install Oh My Posh: $($_.Exception.Message)"
    }

} catch {
    Write-Error "Failed to install development tools: $($_.Exception.Message)"
    exit 1
}

Write-Host "Additional development tools installation completed!" -ForegroundColor Green