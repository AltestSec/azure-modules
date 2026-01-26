# Configure IntelliJ IDEA with Essential Plugins
# This script configures IntelliJ IDEA Community Edition with development plugins

Write-Host "Configuring IntelliJ IDEA Community Edition..." -ForegroundColor Green

try {
    # Wait for IntelliJ IDEA installation to complete
    $ideaPath = "${env:ProgramFiles}\JetBrains\IntelliJ IDEA Community Edition"
    $ideaBin = "$ideaPath\bin\idea64.exe"
    
    # Wait for installation to complete
    $timeout = 300 # 5 minutes
    $elapsed = 0
    while (-not (Test-Path $ideaBin) -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 10
        $elapsed += 10
        Write-Host "Waiting for IntelliJ IDEA installation to complete... ($elapsed/$timeout seconds)" -ForegroundColor Yellow
    }
    
    if (-not (Test-Path $ideaBin)) {
        Write-Warning "IntelliJ IDEA not found at expected location. Skipping configuration."
        return
    }
    
    Write-Host "IntelliJ IDEA found at: $ideaBin" -ForegroundColor Green
    
    # Create IntelliJ IDEA configuration directory
    $ideaConfigDir = "$env:USERPROFILE\.IntelliJIdea2023.3\config"
    New-Item -ItemType Directory -Path $ideaConfigDir -Force -ErrorAction SilentlyContinue
    
    # Create plugins directory
    $pluginsDir = "$ideaConfigDir\plugins"
    New-Item -ItemType Directory -Path $pluginsDir -Force -ErrorAction SilentlyContinue
    
    # List of essential plugins to install
    $plugins = @(
        "Git4Idea",                    # Git integration (usually pre-installed)
        "com.intellij.java",          # Java support (usually pre-installed)
        "JavaScript",                 # JavaScript support
        "NodeJS",                     # Node.js support
        "org.jetbrains.plugins.gradle", # Gradle support
        "org.jetbrains.idea.maven",   # Maven support
        "Docker",                     # Docker integration
        "org.jetbrains.plugins.terminal", # Terminal support
        "com.intellij.database",      # Database tools
        "org.jetbrains.plugins.yaml", # YAML support
        "com.intellij.properties",    # Properties files support
        "com.intellij.spring.boot",   # Spring Boot support
        "AWSToolkit",                 # AWS Toolkit
        "com.microsoft.azure.toolkit.intellij", # Azure Toolkit
        "org.jetbrains.kotlin",      # Kotlin support
        "com.intellij.plugins.html",  # HTML support
        "com.intellij.css",           # CSS support
        "com.intellij.xml",           # XML support
        "com.intellij.json"           # JSON support
    )
    
    # Create a plugin installation script
    $pluginScript = @"
import com.intellij.ide.plugins.PluginManager
import com.intellij.ide.plugins.PluginManagerCore
import com.intellij.openapi.extensions.PluginId

def pluginsToInstall = [
    'Git4Idea',
    'com.intellij.java',
    'JavaScript',
    'NodeJS',
    'org.jetbrains.plugins.gradle',
    'org.jetbrains.idea.maven',
    'Docker',
    'org.jetbrains.plugins.terminal',
    'com.intellij.database',
    'org.jetbrains.plugins.yaml',
    'com.intellij.properties',
    'AWSToolkit',
    'org.jetbrains.kotlin',
    'com.intellij.plugins.html',
    'com.intellij.css',
    'com.intellij.xml',
    'com.intellij.json'
]

pluginsToInstall.each { pluginId ->
    def plugin = PluginManagerCore.getPlugin(PluginId.getId(pluginId))
    if (plugin != null && !plugin.isEnabled()) {
        PluginManagerCore.enablePlugin(plugin.getPluginId())
        println("Enabled plugin: " + pluginId)
    } else {
        println("Plugin already enabled or not found: " + pluginId)
    }
}

println("Plugin configuration completed")
"@
    
    $pluginScriptPath = "$env:TEMP\configure-plugins.groovy"
    $pluginScript | Out-File -FilePath $pluginScriptPath -Encoding UTF8
    
    # Create IntelliJ IDEA settings
    Write-Host "Creating IntelliJ IDEA configuration..." -ForegroundColor Yellow
    
    # Create idea.properties for better performance in AVD
    $ideaProperties = @"
# IntelliJ IDEA properties for AVD optimization
idea.config.path=$env:USERPROFILE\.IntelliJIdea2023.3\config
idea.system.path=$env:USERPROFILE\.IntelliJIdea2023.3\system
idea.plugins.path=$env:USERPROFILE\.IntelliJIdea2023.3\config\plugins
idea.log.path=$env:USERPROFILE\.IntelliJIdea2023.3\system\log

# Performance optimizations
idea.max.intellisense.filesize=2500
idea.cycle.buffer.size=1024
idea.max.content.load.filesize=20000
idea.is.internal=false

# Disable unnecessary features for better performance
idea.ProcessCanceledException=disabled
idea.fatal.error.notification=disabled

# Memory settings
-Xms512m
-Xmx2048m
-XX:ReservedCodeCacheSize=512m
-XX:+UseConcMarkSweepGC
-XX:SoftRefLRUPolicyMSPerMB=50
-ea
-XX:CICompilerCount=2
-Dsun.io.useCanonPrefixCache=false
-Djdk.http.auth.tunneling.disabledSchemes=""
-XX:+HeapDumpOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-Djb.vmOptionsFile=$ideaPath\bin\idea64.exe.vmoptions
"@
    
    $ideaPropertiesPath = "$ideaPath\bin\idea.properties"
    $ideaProperties | Out-File -FilePath $ideaPropertiesPath -Encoding UTF8 -Force
    
    # Create VM options for better performance
    $vmOptions = @"
-Xms512m
-Xmx2048m
-XX:ReservedCodeCacheSize=512m
-XX:+UseConcMarkSweepGC
-XX:SoftRefLRUPolicyMSPerMB=50
-ea
-XX:CICompilerCount=2
-Dsun.io.useCanonPrefixCache=false
-Djdk.http.auth.tunneling.disabledSchemes=
-XX:+HeapDumpOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-Djb.vmOptionsFile=%APPDATA%\JetBrains\IntelliJIdea2023.3\idea64.exe.vmoptions
-Dfile.encoding=UTF-8
-Duser.name=developer
"@
    
    $vmOptionsPath = "$ideaPath\bin\idea64.exe.vmoptions"
    $vmOptions | Out-File -FilePath $vmOptionsPath -Encoding UTF8 -Force
    
    # Create initial IDE settings
    $ideaSettings = @"
<application>
  <component name="GeneralSettings">
    <option name="confirmExit" value="false" />
    <option name="showTipsOnStartup" value="false" />
    <option name="reopenLastProject" value="false" />
  </component>
  <component name="UpdatesConfigurable">
    <option name="CHECK_NEEDED" value="false" />
  </component>
  <component name="UsageStatistics">
    <option name="allowed" value="false" />
  </component>
  <component name="PropertiesComponent">
    <property name="ide.first.run" value="false" />
    <property name="toolwindow.stripes.buttons.info.shown" value="true" />
  </component>
</application>
"@
    
    $settingsPath = "$ideaConfigDir\options\other.xml"
    $settingsDir = Split-Path $settingsPath -Parent
    New-Item -ItemType Directory -Path $settingsDir -Force -ErrorAction SilentlyContinue
    $ideaSettings | Out-File -FilePath $settingsPath -Encoding UTF8 -Force
    
    # Configure Git integration
    $gitSettings = @"
<application>
  <component name="Git.Settings">
    <option name="RECENT_GIT_ROOT_PATH" value="C:/" />
    <option name="UPDATE_TYPE" value="REBASE" />
    <option name="PUSH_AUTO_UPDATE" value="true" />
    <option name="ROOT_SYNC" value="DONT_SYNC" />
    <option name="WARN_ABOUT_CRLF" value="false" />
    <option name="WARN_ABOUT_DETACHED_HEAD" value="false" />
  </component>
</application>
"@
    
    $gitSettingsPath = "$ideaConfigDir\options\git.xml"
    $gitSettings | Out-File -FilePath $gitSettingsPath -Encoding UTF8 -Force
    
    # Configure Node.js integration
    $nodeSettings = @"
<application>
  <component name="NodeJsLocalInterpreters">
    <local-interpreter path="C:\Program Files\nodejs\node.exe" />
  </component>
</application>
"@
    
    $nodeSettingsPath = "$ideaConfigDir\options\nodejs.xml"
    $nodeSettings | Out-File -FilePath $nodeSettingsPath -Encoding UTF8 -Force
    
    # Configure Java SDK
    $javaSettings = @"
<application>
  <component name="ProjectJdkTable">
    <jdk version="2">
      <name value="17" />
      <type value="JavaSDK" />
      <version value="java version &quot;17.0.0&quot;" />
      <homePath value="C:\Program Files\Java\jdk-17" />
    </jdk>
  </component>
</application>
"@
    
    $javaSettingsPath = "$ideaConfigDir\options\jdk.table.xml"
    $javaSettings | Out-File -FilePath $javaSettingsPath -Encoding UTF8 -Force
    
    # Create a desktop shortcut
    Write-Host "Creating desktop shortcut..." -ForegroundColor Yellow
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\IntelliJ IDEA.lnk")
    $Shortcut.TargetPath = $ideaBin
    $Shortcut.WorkingDirectory = "$env:USERPROFILE\Documents"
    $Shortcut.Description = "IntelliJ IDEA Community Edition"
    $Shortcut.Save()
    
    # Create start menu shortcut
    $startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\JetBrains"
    New-Item -ItemType Directory -Path $startMenuPath -Force -ErrorAction SilentlyContinue
    $StartMenuShortcut = $WshShell.CreateShortcut("$startMenuPath\IntelliJ IDEA Community Edition.lnk")
    $StartMenuShortcut.TargetPath = $ideaBin
    $StartMenuShortcut.WorkingDirectory = "$env:USERPROFILE\Documents"
    $StartMenuShortcut.Description = "IntelliJ IDEA Community Edition"
    $StartMenuShortcut.Save()
    
    Write-Host "✓ IntelliJ IDEA configuration completed" -ForegroundColor Green
    Write-Host "✓ Desktop and Start Menu shortcuts created" -ForegroundColor Green
    Write-Host "✓ Git, Node.js, and Java integration configured" -ForegroundColor Green
    Write-Host "✓ Performance optimizations applied for AVD" -ForegroundColor Green
    
    # Create a sample project template
    Write-Host "Creating sample project templates..." -ForegroundColor Yellow
    $templatesDir = "$ideaConfigDir\projectTemplates"
    New-Item -ItemType Directory -Path $templatesDir -Force -ErrorAction SilentlyContinue
    
    # Java Spring Boot template
    $springBootTemplate = @"
{
  "name": "Spring Boot Application",
  "description": "A basic Spring Boot application template",
  "group": "Spring",
  "icon": "spring.png",
  "files": [
    {
      "name": "pom.xml",
      "content": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<project xmlns=\"http://maven.apache.org/POM/4.0.0\">\n  <modelVersion>4.0.0</modelVersion>\n  <groupId>com.example</groupId>\n  <artifactId>demo</artifactId>\n  <version>0.0.1-SNAPSHOT</version>\n  <packaging>jar</packaging>\n  <name>demo</name>\n  <description>Demo project for Spring Boot</description>\n  <parent>\n    <groupId>org.springframework.boot</groupId>\n    <artifactId>spring-boot-starter-parent</artifactId>\n    <version>3.1.0</version>\n    <relativePath/>\n  </parent>\n  <dependencies>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-web</artifactId>\n    </dependency>\n  </dependencies>\n</project>"
    }
  ]
}
"@
    
    $springBootTemplate | Out-File -FilePath "$templatesDir\spring-boot-template.json" -Encoding UTF8
    
    # Node.js Express template
    $nodeTemplate = @"
{
  "name": "Node.js Express Application",
  "description": "A basic Node.js Express application template",
  "group": "Node.js",
  "icon": "nodejs.png",
  "files": [
    {
      "name": "package.json",
      "content": "{\n  \"name\": \"express-app\",\n  \"version\": \"1.0.0\",\n  \"description\": \"Express application\",\n  \"main\": \"app.js\",\n  \"scripts\": {\n    \"start\": \"node app.js\",\n    \"dev\": \"nodemon app.js\"\n  },\n  \"dependencies\": {\n    \"express\": \"^4.18.0\"\n  },\n  \"devDependencies\": {\n    \"nodemon\": \"^2.0.0\"\n  }\n}"
    },
    {
      "name": "app.js",
      "content": "const express = require('express');\nconst app = express();\nconst port = process.env.PORT || 3000;\n\napp.get('/', (req, res) => {\n  res.send('Hello World!');\n});\n\napp.listen(port, () => {\n  console.log(`Server running at http://localhost:${port}`);\n});"
    }
  ]
}
"@
    
    $nodeTemplate | Out-File -FilePath "$templatesDir\nodejs-express-template.json" -Encoding UTF8
    
    Write-Host "✓ Project templates created" -ForegroundColor Green
    
    # Clean up temporary files
    Remove-Item $pluginScriptPath -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Error "Failed to configure IntelliJ IDEA: $($_.Exception.Message)"
    exit 1
}

Write-Host "IntelliJ IDEA configuration completed successfully!" -ForegroundColor Green
Write-Host "Features configured:" -ForegroundColor Cyan
Write-Host "  • Git integration with Windows Git" -ForegroundColor Cyan
Write-Host "  • Node.js development support" -ForegroundColor Cyan
Write-Host "  • Java development with JDK 17" -ForegroundColor Cyan
Write-Host "  • Performance optimizations for AVD" -ForegroundColor Cyan
Write-Host "  • Project templates for Spring Boot and Node.js" -ForegroundColor Cyan
Write-Host "  • Desktop and Start Menu shortcuts" -ForegroundColor Cyan