# Install Office 365 Apps for Enterprise
# This script installs Office 365 with optimized settings for AVD

Write-Host "Starting Office 365 installation..." -ForegroundColor Green

# Create temp directory
$tempDir = "C:\temp\office365"
New-Item -ItemType Directory -Path $tempDir -Force

# Download Office Deployment Tool
$odtUrl = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_16026-20170.exe"
$odtPath = "$tempDir\officedeploymenttool.exe"

try {
    Write-Host "Downloading Office Deployment Tool..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $odtUrl -OutFile $odtPath -UseBasicParsing
    
    # Extract ODT
    Write-Host "Extracting Office Deployment Tool..." -ForegroundColor Yellow
    Start-Process -FilePath $odtPath -ArgumentList "/quiet /extract:$tempDir" -Wait
    
    # Create configuration XML for Office 365
    $configXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="MonthlyEnterprise" MigrateArch="TRUE">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
      <Language ID="de-de" />
      <Language ID="fr-fr" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" />
    </Product>
  </Add>
  <Property Name="SharedComputerLicensing" Value="1" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Property Name="DeviceBasedLicensing" Value="0" />
  <Property Name="SCLCacheOverride" Value="0" />
  <Property Name="AUTOACTIVATE" Value="1" />
  <Updates Enabled="TRUE" />
  <RemoveMSI />
  <AppSettings>
    <Setup Name="Company" Value="AVD Environment" />
    <User Key="software\microsoft\office\16.0\excel\options" Name="defaultformat" Value="51" Type="REG_DWORD" App="excel16" Id="L_SaveExcelfilesas" />
    <User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas" />
    <User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas" />
  </AppSettings>
  <Display Level="None" AcceptEULA="TRUE" />
  <Logging Level="Standard" Path="%temp%" />
</Configuration>
"@

    $configPath = "$tempDir\configuration.xml"
    $configXml | Out-File -FilePath $configPath -Encoding UTF8
    
    # Install Office 365
    Write-Host "Installing Office 365 Apps for Enterprise..." -ForegroundColor Yellow
    $setupPath = "$tempDir\setup.exe"
    Start-Process -FilePath $setupPath -ArgumentList "/configure $configPath" -Wait -NoNewWindow
    
    Write-Host "Office 365 installation completed successfully!" -ForegroundColor Green
    
    # Configure Office for AVD optimization
    Write-Host "Configuring Office for AVD optimization..." -ForegroundColor Yellow
    
    # Disable Office animations
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common" -Name "DisableAnimations" -Value 1 -Type DWord
    
    # Enable shared computer activation
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name "SharedComputerLicensing" -Value 1 -Type DWord
    
    # Disable Office telemetry
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\privacy" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\privacy" -Name "DisconnectedState" -Value 2 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\privacy" -Name "UserContentDisabled" -Value 2 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\privacy" -Name "DownloadContentDisabled" -Value 2 -Type DWord
    
    # Configure Outlook for cached mode
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\outlook\cached mode" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\outlook\cached mode" -Name "enable" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\outlook\cached mode" -Name "syncwindowsetting" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\outlook\cached mode" -Name "CalendarSyncWindowSetting" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\outlook\cached mode" -Name "CalendarSyncWindowSettingMonths" -Value 1 -Type DWord
    
    Write-Host "Office 365 optimization completed!" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to install Office 365: $($_.Exception.Message)"
    exit 1
} finally {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Office 365 installation and configuration completed successfully!" -ForegroundColor Green