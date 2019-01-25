################################################################################
##  File:  Initialize-VM.ps1
##  Team:  CI-Platform
##  Desc:  VM initialization script, machine level configuration
################################################################################

function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force -ErrorAction Continue
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled."
}

function Disable-InternetExplorerWelcomeScreen {
    $AdminKey = "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main"
    New-Item -Path $AdminKey -Value 1 -Force
    Set-ItemProperty -Path $AdminKey -Name "DisableFirstRunCustomize" -Value 1 -Force
    Write-Host "Disabled IE Welcome screen"
}

function Disable-UserAccessControl {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -Force
    Write-Host "User Access Control (UAC) has been disabled."
}

Import-Module -Name ImageHelpers -Force

Write-Host "Setup PowerShellGet"
# Set-PSRepository -InstallationPolicy Trusted -Name PSGallery
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PowerShellGet -Force
Set-PSRepository -InstallationPolicy Trusted -Name PSGallery


Write-Host "Disable Antivirus"
Set-MpPreference -DisableRealtimeMonitoring $true

# Disable Windows Update
$AutoUpdatePath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
If (Test-Path -Path $AutoUpdatePath) {
    Set-ItemProperty -Path $AutoUpdatePath -Name NoAutoUpdate -Value 1
    Write-Host "Disabled Windows Update"
}
else {
    Write-Host "Windows Update key does not exist"
}

# Install .NET Framework 3.5 (required by Chocolatey)
Install-WindowsFeature -Name NET-Framework-Features -IncludeAllSubFeature
# Explicitly install all 4.7 sub features to include ASP.Net. 
# As of  1/16/2019, WinServer 19 lists .Net 4.7 as NET-Framework-45-Features
Install-WindowsFeature -Name NET-Framework-45-Features -IncludeAllSubFeature

Write-Host "Disable UAC"
Disable-UserAccessControl

Write-Host "Disable IE Welcome Screen"
Disable-InternetExplorerWelcomeScreen

Write-Host "Disable IE ESC"
Disable-InternetExplorerESC

Write-Host "Setting local execution policy"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine  -ErrorAction Continue | Out-Null
Get-ExecutionPolicy -List


Write-Host "Install chocolatey"
$chocoExePath = 'C:\ProgramData\Chocolatey\bin'

if ($($env:Path).ToLower().Contains($($chocoExePath).ToLower())) {
    Write-Host "Chocolatey found in PATH, skipping install..."
    Exit
}

# Add to system PATH
$systemPath = [Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)
$systemPath += ';' + $chocoExePath
[Environment]::SetEnvironmentVariable("PATH", $systemPath, [System.EnvironmentVariableTarget]::Machine)

# Update local process' path
$userPath = [Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User)
if ($userPath) {
    $env:Path = $systemPath + ";" + $userPath
}
else {
    $env:Path = $systemPath
}

# Run the installer
Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

# Turn off confirmation
choco feature enable -n allowGlobalConfirmation

# Install webpi
choco install webpicmd -y

# Expand disk size of OS drive

New-Item -Path d:\ -Name cmds.txt -ItemType File -Force

Add-Content -Path d:\cmds.txt "SELECT VOLUME=C`r`nEXTEND"

$expandResult = (diskpart /s 'd:\cmds.txt')

Write-Host $expandResult

Write-Host "Disk sizes after expansion"

wmic logicaldisk get size,freespace,caption


# Adding description of the software to Markdown

$Content = @"
# Azure Pipelines Hosted Windows 2019 with VS2019 image

The following software is installed on machines in the Azure Pipelines **Hosted Windows 2019 with VS2019** pool.

Components marked with **\*** have been upgraded since the previous version of the image.

"@

Add-ContentToMarkdown -Content $Content


$SoftwareName = "Chocolatey"

if( $( $(choco version) | Out-String) -match  'Chocolatey v(?<version>.*).*' )
{
   $chocoVersion = $Matches.version.Trim()
}

$Description = @"
_Version:_ $chocoVersion<br/>
_Environment:_
* PATH: contains location for choco.exe
"@

Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description
