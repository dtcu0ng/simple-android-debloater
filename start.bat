@echo off
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/dtcu0ng/simple-android-debloater/main/script.ps1' | Invoke-Expression}"
pause
exit