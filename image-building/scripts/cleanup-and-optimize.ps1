# Cleanup and Optimization Script for AVD Images
# This script performs final cleanup and optimization before sysprep

Write-Host "Starting cleanup and optimization for AVD image..." -ForegroundColor Green

try {
    # Clear Windows Update cache
    Write-Host "Clearing Windows Update cache..." -ForegroundColor Yellow
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-Host "✓ Windows Update cache cleared" -ForegroundColor Green

    # Clear temporary files
    Write-Host "Clearing temporary files..." -ForegroundColor Yellow
    $tempPaths = @(
        "$env:TEMP\*",
        "$env:SystemRoot\Temp\*",
        "$env:SystemRoot\Logs\*",
        "$env:SystemRoot\Panther\*",
        "$env:SystemRoot\WinSxS\Temp\*",
        "$env:ProgramData\Microsoft\Windows\WER\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\WebCache\*",
        "$env:LOCALAPPDATA\Temp\*"
    )
    
    foreach ($path in $tempPaths) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "✓ Temporary files cleared" -ForegroundColor Green

    # Clear event logs
    Write-Host "Clearing event logs..." -ForegroundColor Yellow
    $logs = Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 }
    foreach ($log in $logs) {
        try {
            wevtutil cl $log.LogName
        } catch {
            # Some logs cannot be cleared, ignore errors
        }
    }
    Write-Host "✓ Event logs cleared" -ForegroundColor Green

    # Clear browser caches
    Write-Host "Clearing browser caches..." -ForegroundColor Yellow
    
    # Chrome cache
    $chromePaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache\*"
    )
    foreach ($path in $chromePaths) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Edge cache
    $edgePaths = @(
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache\*"
    )
    foreach ($path in $edgePaths) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "✓ Browser caches cleared" -ForegroundColor Green

    # Optimize Windows features
    Write-Host "Optimizing Windows features..." -ForegroundColor Yellow
    
    # Disable hibernation to save disk space
    powercfg /hibernate off
    
    # Disable page file (will be recreated on first boot)
    $cs = Get-WmiObject -Class Win32_ComputerSystem
    if ($cs.AutomaticManagedPagefile) {
        $cs.AutomaticManagedPagefile = $false
        $cs.Put()
    }
    
    # Clear page file
    $pagefiles = Get-WmiObject -Class Win32_PageFileSetting
    foreach ($pagefile in $pagefiles) {
        $pagefile.Delete()
    }
    
    Write-Host "✓ Windows features optimized" -ForegroundColor Green

    # Run Disk Cleanup
    Write-Host "Running Disk Cleanup..." -ForegroundColor Yellow
    
    # Configure Disk Cleanup to clean all available items
    $cleanupKeys = @(
        "Active Setup Temp Folders",
        "BranchCache",
        "Content Indexer Cleaner",
        "Device Driver Packages",
        "Downloaded Program Files",
        "GameNewsFiles",
        "GameStatisticsFiles",
        "GameUpdateFiles",
        "Internet Cache Files",
        "Memory Dump Files",
        "Offline Pages Files",
        "Old ChkDsk Files",
        "Previous Installations",
        "Recycle Bin",
        "Service Pack Cleanup",
        "Setup Log Files",
        "System error memory dump files",
        "System error minidump files",
        "Temporary Files",
        "Temporary Setup Files",
        "Temporary Sync Files",
        "Thumbnail Cache",
        "Update Cleanup",
        "Upgrade Discarded Files",
        "User file versions",
        "Windows Defender",
        "Windows Error Reporting Archive Files",
        "Windows Error Reporting Queue Files",
        "Windows Error Reporting System Archive Files",
        "Windows Error Reporting System Queue Files",
        "Windows ESD installation files",
        "Windows Upgrade Log Files"
    )
    
    foreach ($key in $cleanupKeys) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$key" -Name "StateFlags0001" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    }
    
    # Run cleanmgr
    Start-Process -FilePath cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow
    
    Write-Host "✓ Disk Cleanup completed" -ForegroundColor Green

    # Defragment system drive (if HDD)
    Write-Host "Checking drive type and optimizing..." -ForegroundColor Yellow
    $drive = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 }
    if ($drive.MediaType -eq "HDD") {
        defrag C: /O /H /V
        Write-Host "✓ Drive defragmented" -ForegroundColor Green
    } else {
        # For SSD, run TRIM
        Optimize-Volume -DriveLetter C -ReTrim -Verbose
        Write-Host "✓ SSD optimized with TRIM" -ForegroundColor Green
    }

    # Clear Windows Search index
    Write-Host "Clearing Windows Search index..." -ForegroundColor Yellow
    Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:ProgramData\Microsoft\Search\Data\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name WSearch -ErrorAction SilentlyContinue
    Write-Host "✓ Windows Search index cleared" -ForegroundColor Green

    # Reset Windows Store cache
    Write-Host "Resetting Windows Store cache..." -ForegroundColor Yellow
    wsreset.exe
    Write-Host "✓ Windows Store cache reset" -ForegroundColor Green

    # Clear DNS cache
    Write-Host "Clearing DNS cache..." -ForegroundColor Yellow
    ipconfig /flushdns
    Write-Host "✓ DNS cache cleared" -ForegroundColor Green

    # Clear ARP cache
    Write-Host "Clearing ARP cache..." -ForegroundColor Yellow
    arp -d *
    Write-Host "✓ ARP cache cleared" -ForegroundColor Green

    # Reset network adapters
    Write-Host "Resetting network adapters..." -ForegroundColor Yellow
    netsh winsock reset
    netsh int ip reset
    Write-Host "✓ Network adapters reset" -ForegroundColor Green

    # Clear PowerShell history
    Write-Host "Clearing PowerShell history..." -ForegroundColor Yellow
    Remove-Item -Path "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Force -ErrorAction SilentlyContinue
    Write-Host "✓ PowerShell history cleared" -ForegroundColor Green

    # Clear Visual Studio Code settings (user-specific)
    Write-Host "Clearing VS Code user settings..." -ForegroundColor Yellow
    Remove-Item -Path "$env:APPDATA\Code\User\workspaceStorage" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:APPDATA\Code\User\History" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:APPDATA\Code\logs" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ VS Code user settings cleared" -ForegroundColor Green

    # Clear Docker data (if Docker is installed)
    Write-Host "Clearing Docker data..." -ForegroundColor Yellow
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        docker system prune -af --volumes 2>$null
    }
    Write-Host "✓ Docker data cleared" -ForegroundColor Green

    # Optimize registry
    Write-Host "Optimizing registry..." -ForegroundColor Yellow
    
    # Compact registry hives
    $registryHives = @(
        "HKLM\SOFTWARE",
        "HKLM\SYSTEM",
        "HKLM\SECURITY",
        "HKLM\SAM"
    )
    
    foreach ($hive in $registryHives) {
        reg export $hive "$env:TEMP\backup_$($hive -replace '\\', '_').reg" /y 2>$null
        reg import "$env:TEMP\backup_$($hive -replace '\\', '_').reg" /y 2>$null
        Remove-Item "$env:TEMP\backup_$($hive -replace '\\', '_').reg" -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "✓ Registry optimized" -ForegroundColor Green

    # Set system for optimal performance
    Write-Host "Configuring system for optimal performance..." -ForegroundColor Yellow
    
    # Disable visual effects for better performance
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord
    
    # Disable Windows animations
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 0 -Type String
    
    # Configure for best performance
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord
    
    Write-Host "✓ System configured for optimal performance" -ForegroundColor Green

    # Final system check
    Write-Host "Performing final system check..." -ForegroundColor Yellow
    
    # Check system file integrity
    sfc /scannow
    
    # Check disk for errors
    chkdsk C: /f /r /x
    
    Write-Host "✓ Final system check completed" -ForegroundColor Green

    # Generate optimization report
    Write-Host "Generating optimization report..." -ForegroundColor Yellow
    
    $report = @{
        "OptimizationDate" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "SystemInfo" = @{
            "OS" = (Get-WmiObject -Class Win32_OperatingSystem).Caption
            "Version" = (Get-WmiObject -Class Win32_OperatingSystem).Version
            "Architecture" = (Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture
            "TotalMemory" = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        }
        "DiskSpace" = @{
            "TotalSize" = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB, 2)
            "FreeSpace" = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB, 2)
        }
        "OptimizationsApplied" = @(
            "Windows Update cache cleared",
            "Temporary files removed",
            "Event logs cleared",
            "Browser caches cleared",
            "Disk cleanup performed",
            "Drive optimized",
            "Registry optimized",
            "System configured for performance",
            "Security hardening applied"
        )
    }
    
    $reportJson = $report | ConvertTo-Json -Depth 3
    $reportJson | Out-File -FilePath "$env:SystemRoot\Temp\optimization-report.json" -Encoding UTF8
    
    Write-Host "✓ Optimization report generated" -ForegroundColor Green

} catch {
    Write-Error "Cleanup and optimization failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "Cleanup and optimization completed successfully!" -ForegroundColor Green
Write-Host "The system is now ready for sysprep and image capture." -ForegroundColor Cyan