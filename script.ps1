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
    Write-Output "-----------------------------------------------------------------"
    Write-Output "Simple Android debloater"
    Write-Output "Source code: https://github.com/dtcu0ng/simple-android-debloater"
    Write-Output "(c) dtcu0ng"
    Write-Output "-----------------------------------------------------------------"
}
if (($AdbFiles | ForEach-Object {test-path $AdbPath\$_}) -contains $false) {
    Write-Output "Not found neccessary ADB file in folder $AdbPath."
    $message = Read-Host -Prompt "Would you like to download minimal-platform-tools? (Y/N)"
    if ($message -eq 'y'){
        Write-Output "Downloading platform-tools... (Usually this will take 2-3 min, depend on your internet connection.)"
        GetFile "$pt_url" -UseBasicParsing -OutFile "$pt_archive_name"
        Write-Output "Download completed. Expanding compressed files..."
        Expand-Archive -LiteralPath $pt_archive_name
        Get-ChildItem -Path "$pt_archive_name" -Recurse |  Move-Item -Destination .
        Write-Output "Extracted."
    } else {
        Write-Output "You selected No. This program will not run if missing ADB files."
        Write-Output "Make sure you gather all $AdbFiles and save it to platform-tools folder in the script dir."
        exit 1
    }
}
if (-not (Test-Path -Path $AppListPath)) {
    Write-Output "App list JSON file not found in $AppListPath."
    $AppListPath = Read-Host -Prompt "Please specify path in this prompt (You can drag'n drop app list JSON file to this window.)"
    if ($AppListPath -eq [string]::empty){
        Write-Output "Invaild App list JSON path. Please download the app list JSON and place it to $AppListPath."
        exit 1
    }
    $AppListData = Get-Content -Raw -Path $AppListPath | ConvertFrom-Json
} else {
    $AppListData = Get-Content -Raw -Path $AppListPath | ConvertFrom-Json
}

function Uninstall {
    for ($i=0; $i -lt $NumberOfApps; $i=$i+1 ) {
        $UninstallState = $AppListData[$i].uninstall
        $AppPackage = $AppListData[$i].package
        if ($UninstallState -eq "yes"){
            Write-Output "Disabling $AppPackage"
            Run "$AdbPath/adb.exe shell pm disable-user $AppPackage"
            Write-Output "Uninstalling $AppPackage"
            Run "$AdbPath/adb.exe shell pm uninstall --user 0 $AppPackage"
            #TODO: use try catch to catch errors
        } else {
            Write-Output ("Skipped ${AppPackage}: $UninstallState")
        }
    }
    Write-Output ("Action completed with ${AppListData.Count} app(s) from list $AppListPath")
    exit
}

function CheckDevices {
    Write-Output "To begin, you should connect only one device and enable USB debugging in your device's Developer Settings "
    $message = Read-Host -Prompt "Press Y to continue."
    if ($message -ne 'y'){
        Write-Output "You're not ready? That's okay. Run the script again when you're ready. "
        exit
    } else {
        Run "$AdbPath/adb kill-server"
        Run "$AdbPath/adb devices"
        $message = Read-Host -Prompt "Do you see your device in the list below? (Y/n)"
        if ($message -eq "y"){
            Pause
            Write-Output "Starting uninstall apps with list $AppListPath"
            Uninstall
        } else {
            Write-Output "Please reconnect your device."
            Write-Output "Make sure you have enabled USB Debugging in your phone's Developer settings then run the script again."
            exit
        }
    }
}

function Main {
    Header
    CheckDevices
}

Main