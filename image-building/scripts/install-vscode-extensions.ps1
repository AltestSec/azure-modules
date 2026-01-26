# Install VS Code Extensions for Development Environment
# This script installs essential VS Code extensions for developers

Write-Host "Installing VS Code extensions..." -ForegroundColor Green

# List of essential extensions for developers
$extensions = @(
    "ms-vscode.vscode-typescript-next",
    "ms-python.python",
    "ms-dotnettools.csharp",
    "ms-vscode.powershell",
    "ms-azuretools.vscode-azureterraform",
    "hashicorp.terraform",
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "ms-vscode.azure-account",
    "ms-azuretools.vscode-azureresourcegroups",
    "ms-azuretools.vscode-azurefunctions",
    "ms-azuretools.vscode-docker",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-vscode.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-github-pullrequest",
    "github.copilot",
    "github.copilot-chat",
    "ms-vscode-remote.remote-containers",
    "ms-vscode-remote.remote-ssh",
    "ms-vscode-remote.remote-wsl",
    "ms-vscode.remote-explorer",
    "ms-vscode.hexeditor",
    "ms-vscode.vscode-thunder-client",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense",
    "ms-vscode.vscode-todo-highlight",
    "gruntfuggly.todo-tree",
    "ms-vscode.vscode-icons",
    "pkief.material-icon-theme",
    "zhuangtongfa.material-theme",
    "ms-vscode.vscode-markdown-preview-enhanced"
)

try {
    # Check if VS Code is installed
    $vscodePath = Get-Command "code" -ErrorAction SilentlyContinue
    if (-not $vscodePath) {
        Write-Warning "VS Code not found in PATH. Extensions will be installed when VS Code is available."
        return
    }

    Write-Host "Found VS Code at: $($vscodePath.Source)" -ForegroundColor Yellow

    # Install each extension
    foreach ($extension in $extensions) {
        try {
            Write-Host "Installing extension: $extension" -ForegroundColor Cyan
            & code --install-extension $extension --force
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Successfully installed: $extension" -ForegroundColor Green
            } else {
                Write-Warning "Failed to install: $extension"
            }
        } catch {
            Write-Warning "Error installing $extension`: $($_.Exception.Message)"
        }
    }

    # Configure VS Code settings for optimal performance in AVD
    $settingsPath = "$env:APPDATA\Code\User\settings.json"
    $settingsDir = Split-Path $settingsPath -Parent
    
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force
    }

    $vscodeSettings = @{
        "telemetry.telemetryLevel" = "off"
        "update.mode" = "manual"
        "extensions.autoUpdate" = $false
        "workbench.enableExperiments" = $false
        "workbench.settings.enableNaturalLanguageSearch" = $false
        "editor.minimap.enabled" = $false
        "editor.renderWhitespace" = "boundary"
        "editor.renderControlCharacters" = $true
        "editor.insertSpaces" = $true
        "editor.tabSize" = 2
        "editor.detectIndentation" = $true
        "editor.wordWrap" = "on"
        "editor.formatOnSave" = $true
        "editor.codeActionsOnSave" = @{
            "source.fixAll.eslint" = $true
        }
        "files.autoSave" = "afterDelay"
        "files.autoSaveDelay" = 1000
        "files.trimTrailingWhitespace" = $true
        "files.insertFinalNewline" = $true
        "terminal.integrated.defaultProfile.windows" = "PowerShell"
        "terminal.integrated.profiles.windows" = @{
            "PowerShell" = @{
                "source" = "PowerShell"
                "icon" = "terminal-powershell"
            }
            "Command Prompt" = @{
                "path" = @(
                    "${env:windir}\Sysnative\cmd.exe",
                    "${env:windir}\System32\cmd.exe"
                )
                "args" = @()
                "icon" = "terminal-cmd"
            }
            "Git Bash" = @{
                "source" = "Git Bash"
            }
        }
        "git.enableSmartCommit" = $true
        "git.confirmSync" = $false
        "git.autofetch" = $true
        "python.defaultInterpreterPath" = "python"
        "python.terminal.activateEnvironment" = $true
        "terraform.experimentalFeatures" = @{
            "validateOnSave" = $true
            "prefillRequiredFields" = $true
        }
        "workbench.iconTheme" = "material-icon-theme"
        "workbench.colorTheme" = "One Dark Pro"
        "security.workspace.trust.untrustedFiles" = "open"
        "remote.SSH.remotePlatform" = @{}
        "docker.showStartPage" = $false
    }

    $settingsJson = $vscodeSettings | ConvertTo-Json -Depth 10
    $settingsJson | Out-File -FilePath $settingsPath -Encoding UTF8 -Force

    Write-Host "VS Code settings configured for AVD optimization" -ForegroundColor Green

    # Create workspace templates
    $workspaceTemplatesDir = "$env:USERPROFILE\Documents\VSCode-Workspaces"
    New-Item -ItemType Directory -Path $workspaceTemplatesDir -Force

    # Create a sample workspace for development projects
    $devWorkspace = @{
        "folders" = @(
            @{
                "name" = "Project Root"
                "path" = "."
            }
        )
        "settings" = @{
            "editor.tabSize" = 2
            "editor.insertSpaces" = $true
        }
        "extensions" = @{
            "recommendations" = @(
                "ms-python.python",
                "ms-vscode.vscode-typescript-next",
                "hashicorp.terraform",
                "ms-azuretools.vscode-docker"
            )
        }
    }

    $workspaceJson = $devWorkspace | ConvertTo-Json -Depth 10
    $workspaceJson | Out-File -FilePath "$workspaceTemplatesDir\development-template.code-workspace" -Encoding UTF8 -Force

    Write-Host "VS Code workspace templates created" -ForegroundColor Green

} catch {
    Write-Error "Failed to configure VS Code extensions: $($_.Exception.Message)"
    exit 1
}

Write-Host "VS Code extensions installation and configuration completed!" -ForegroundColor Green