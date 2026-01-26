# Security Hardening Script for AVD Development Images
# This script applies security best practices for AVD environments

Write-Host "Starting security hardening for AVD development environment..." -ForegroundColor Green

try {
    # Enable Windows Defender and configure settings
    Write-Host "Configuring Windows Defender..." -ForegroundColor Yellow
    
    # Enable real-time protection
    Set-MpPreference -DisableRealtimeMonitoring $false
    
    # Enable cloud protection
    Set-MpPreference -MAPSReporting Advanced
    Set-MpPreference -SubmitSamplesConsent SendAllSamples
    
    # Configure scan settings
    Set-MpPreference -ScanAvgCPULoadFactor 50
    Set-MpPreference -ScanOnlyIfIdleEnabled $true
    
    # Add exclusions for development tools (to improve performance)
    $exclusions = @(
        "$env:ProgramFiles\Microsoft VS Code",
        "$env:ProgramFiles\Git",
        "$env:ProgramFiles\Docker",
        "$env:USERPROFILE\.vscode",
        "$env:USERPROFILE\.docker",
        "$env:USERPROFILE\AppData\Local\Programs\Microsoft VS Code"
    )
    
    foreach ($exclusion in $exclusions) {
        if (Test-Path $exclusion) {
            Add-MpPreference -ExclusionPath $exclusion
        }
    }
    
    Write-Host "✓ Windows Defender configured" -ForegroundColor Green

    # Configure Windows Firewall
    Write-Host "Configuring Windows Firewall..." -ForegroundColor Yellow
    
    # Enable firewall for all profiles
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    
    # Allow development tools through firewall
    $firewallRules = @(
        @{ Name = "Docker Desktop"; Program = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe" },
        @{ Name = "VS Code"; Program = "$env:ProgramFiles\Microsoft VS Code\Code.exe" },
        @{ Name = "Node.js"; Program = "$env:ProgramFiles\nodejs\node.exe" },
        @{ Name = "Python"; Program = "$env:ProgramFiles\Python*\python.exe" }
    )
    
    foreach ($rule in $firewallRules) {
        if (Test-Path $rule.Program) {
            New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Program $rule.Program -Action Allow -ErrorAction SilentlyContinue
            New-NetFirewallRule -DisplayName $rule.Name -Direction Outbound -Program $rule.Program -Action Allow -ErrorAction SilentlyContinue
        }
    }
    
    Write-Host "✓ Windows Firewall configured" -ForegroundColor Green

    # Configure User Account Control (UAC)
    Write-Host "Configuring User Account Control..." -ForegroundColor Yellow
    
    # Set UAC to prompt for credentials for non-Windows binaries
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -Value 3 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableInstallerDetection" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableSecureUIAPaths" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableUIADesktopToggle" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableVirtualization" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ValidateAdminCodeSignatures" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "FilterAdministratorToken" -Value 0 -Type DWord
    
    Write-Host "✓ User Account Control configured" -ForegroundColor Green

    # Disable unnecessary services
    Write-Host "Disabling unnecessary services..." -ForegroundColor Yellow
    
    $servicesToDisable = @(
        "Fax",
        "WerSvc",
        "Spooler",
        "XblAuthManager",
        "XblGameSave",
        "XboxNetApiSvc",
        "XboxGipSvc"
    )
    
    foreach ($service in $servicesToDisable) {
        try {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc -and $svc.StartType -ne "Disabled") {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Host "  ✓ Disabled service: $service" -ForegroundColor Cyan
            }
        } catch {
            Write-Warning "Could not disable service: $service"
        }
    }
    
    Write-Host "✓ Unnecessary services disabled" -ForegroundColor Green

    # Configure Windows Update settings
    Write-Host "Configuring Windows Update..." -ForegroundColor Yellow
    
    # Set Windows Update to download and install automatically
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 4 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AutoInstallMinorUpdates" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "ScheduledInstallDay" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "ScheduledInstallTime" -Value 3 -Type DWord
    
    Write-Host "✓ Windows Update configured" -ForegroundColor Green

    # Configure PowerShell execution policy
    Write-Host "Configuring PowerShell execution policy..." -ForegroundColor Yellow
    
    # Set execution policy to RemoteSigned for development work
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
    
    Write-Host "✓ PowerShell execution policy configured" -ForegroundColor Green

    # Configure network security
    Write-Host "Configuring network security..." -ForegroundColor Yellow
    
    # Disable SMBv1
    Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
    
    # Configure SMBv2/v3 security
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force
    
    # Disable NetBIOS over TCP/IP
    $adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    foreach ($adapter in $adapters) {
        $adapter.SetTcpipNetbios(2)  # 2 = Disable NetBIOS over TCP/IP
    }
    
    Write-Host "✓ Network security configured" -ForegroundColor Green

    # Configure registry security settings
    Write-Host "Applying registry security settings..." -ForegroundColor Yellow
    
    # Disable AutoRun for all drives
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -Type DWord
    
    # Disable Windows Script Host
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings" -Name "Enabled" -Value 0 -Type DWord
    
    # Configure Internet Explorer security
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 1 -Type DWord
    
    # Disable Windows Error Reporting
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1 -Type DWord
    
    Write-Host "✓ Registry security settings applied" -ForegroundColor Green

    # Configure audit policies
    Write-Host "Configuring audit policies..." -ForegroundColor Yellow
    
    # Enable audit policies for security events
    auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
    auditpol /set /category:"Account Logon" /success:enable /failure:enable
    auditpol /set /category:"Account Management" /success:enable /failure:enable
    auditpol /set /category:"Policy Change" /success:enable /failure:enable
    auditpol /set /category:"Privilege Use" /success:enable /failure:enable
    auditpol /set /category:"System" /success:enable /failure:enable
    
    Write-Host "✓ Audit policies configured" -ForegroundColor Green

    # Configure local security policies
    Write-Host "Configuring local security policies..." -ForegroundColor Yellow
    
    # Set password policy (for local accounts)
    secedit /export /cfg "$env:TEMP\secpol.cfg"
    $secpolContent = Get-Content "$env:TEMP\secpol.cfg"
    $secpolContent = $secpolContent -replace "MinimumPasswordAge = .*", "MinimumPasswordAge = 1"
    $secpolContent = $secpolContent -replace "MaximumPasswordAge = .*", "MaximumPasswordAge = 90"
    $secpolContent = $secpolContent -replace "MinimumPasswordLength = .*", "MinimumPasswordLength = 12"
    $secpolContent = $secpolContent -replace "PasswordComplexity = .*", "PasswordComplexity = 1"
    $secpolContent | Set-Content "$env:TEMP\secpol.cfg"
    secedit /configure /db "$env:TEMP\secedit.sdb" /cfg "$env:TEMP\secpol.cfg" /areas SECURITYPOLICY
    
    Write-Host "✓ Local security policies configured" -ForegroundColor Green

    # Enable Windows Defender Application Guard (if supported)
    Write-Host "Checking Windows Defender Application Guard..." -ForegroundColor Yellow
    try {
        $wdagFeature = Get-WindowsOptionalFeature -Online -FeatureName "Windows-Defender-ApplicationGuard"
        if ($wdagFeature.State -eq "Disabled") {
            Enable-WindowsOptionalFeature -Online -FeatureName "Windows-Defender-ApplicationGuard" -NoRestart
            Write-Host "✓ Windows Defender Application Guard enabled" -ForegroundColor Green
        } else {
            Write-Host "✓ Windows Defender Application Guard already enabled" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Windows Defender Application Guard not supported on this system"
    }

    # Configure BitLocker (if TPM is available)
    Write-Host "Checking BitLocker availability..." -ForegroundColor Yellow
    try {
        $tpm = Get-Tpm
        if ($tpm.TpmPresent -and $tpm.TpmReady) {
            # Enable BitLocker for system drive
            Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector
            Write-Host "✓ BitLocker enabled for system drive" -ForegroundColor Green
        } else {
            Write-Warning "TPM not available - BitLocker not configured"
        }
    } catch {
        Write-Warning "BitLocker configuration failed: $($_.Exception.Message)"
    }

    # Clean up temporary files
    Remove-Item "$env:TEMP\secpol.cfg" -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\secedit.sdb" -ErrorAction SilentlyContinue

} catch {
    Write-Error "Security hardening failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "Security hardening completed successfully!" -ForegroundColor Green
Write-Host "The system is now configured with enhanced security settings for AVD development environment." -ForegroundColor Cyan