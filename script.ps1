#Requires -Version 5.1
$AppListPath = "./resources/app-list.json" # default app-list json file path
#$AppListPath = "./resources/device-info.json"
$AdbPath = "minimal-platform-tools"
$AdbFiles = @('adb.exe','AdbWinApi.dll','AdbWinUsbApi.dll')
$pt_archive_name = "minimal-platform-tools.zip"
$pt_url = "https://dtcu0ng.github.io/binary/minimal-platform-tools.zip"

$checkAdmin = "on"

Set-Alias -Name GetFile -Value "Invoke-WebRequest"
Set-Alias -Name Run -Value "Invoke-Expression"


if ( "$checkAdmin" -eq "on" ) {
	if ( [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")) { # thank to https://superuser.com/questions/749243/detect-if-powershell-is-running-as-administrator
		Write-Output "This script is running as administrator, this is discouraged."
		Write-Output "It is recommended to run it as a normal user as it doesn't need further permissions."
		exit 1
    }
}
function Header {
    Write-Host "------------------"
    Write-Host "Simple Android debloater"
    Write-Host "Source code: https://github.com/dtcu0ng/simple-android-debloater"
    Write-Host "(c) dtcu0ng"
    Write-Host "------------------"
}
if (($AdbFiles | ForEach-Object {test-path $AdbPath\$_}) -contains $false) {
    $message = Read-Host -Prompt "Not found neccessary ADB file in folder $AdbPath. Would you like to download minimal-platform-tools? (Y/N)"
    if ($message -eq 'y'){
        Write-Output "Downloading platform-tools... (Usually this will take 2-3 min, depend on your internet connection.)"
        GetFile "$pt_url" -UseBasicParsing -OutFile "$pt_archive_name"
        Write-Output "Download completed. Expanding compressed files..."
        Expand-Archive -LiteralPath $pt_archive_name
        Get-ChildItem -Path "$pt_archive_name" -Recurse |  Move-Item -Destination .
        Write-Output "Extracted."
    } else {
        Write-Output "You selected No. This program will not run if missing ADB files. Make sure you gather all $AdbFiles and save it to platform-tools folder in the script dir."
    }
}
if (-not (Test-Path -Path $AppListPath)) {
    $AppListPath = Read-Host -Prompt "App list JSON file not found in $AppListPath. Please specify path in this prompt"
    if ($AppListPath -eq [string]::empty){
        Write-Output "Invaild App list JSON path. Please download the app list JSON and place it to $AppListPath."
        exit 1
    }
    $AppListData = Get-Content -Raw -Path $AppListPath | ConvertFrom-Json
} else {
    $AppListData = Get-Content -Raw -Path $AppListPath | ConvertFrom-Json
}

function Uninstall {
    for ($i=0; $i -lt $AppListData.Count; $i=$i+1 ) {
        if ($AppListData[$i].uninstall -eq "yes"){
            Write-Host "Disabling" $AppListData[$i].package
            Run "$AdbPath/adb.exe shell pm disable-user $AppListData[$i].package"
            Write-Host "Uninstalling" $AppListData[$i].package
            Run "$AdbPath/adb.exe shell pm uninstall --user 0 $AppListData[$i].package"
        } else {
            Write-Host "Skipped" $AppListData[$i].package "( uninstall state:" $AppListData[$i].uninstall ")"
        }
    
    }    
}

function CheckDevices {
    Write-Host "To begin, you should connect only one device and enable USB debugging in your device's Developer Settings "
    $message = Read-Host -Prompt "Press Y to continue."
    if ($message -eq 'y'){
        Run "$AdbPath/adb kill-server"
        Run "$AdbPath/adb devices"
        $message = Read-Host -Prompt "Do you see your device in the list below? (Y/n)"
        if ($message -eq "y"){
            Pause
            Write-Host "Starting uninstall apps with list $AppListPath"
            Uninstall
        }
    }  
}

function Main {
    Header
    CheckDevices
}

Main