# Run from an ordinary PowerShell terminal; no background processes required.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
$androidSdkPath = "$env:LOCALAPPDATA\Android\Sdk"
$env:ANDROID_SDK_ROOT = $androidSdkPath
$env:ANDROID_HOME = $androidSdkPath

Write-Host "Project: $(Get-Location)" -ForegroundColor Cyan
Get-Content .\pubspec.yaml | Select-String 'version:'

flutter pub get
if ($LASTEXITCODE -ne 0) { throw "Flutter dependencies failed" }
flutter analyze --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed" }
flutter test
if ($LASTEXITCODE -ne 0) { throw "flutter test failed" }
flutter build apk --debug
if ($LASTEXITCODE -ne 0) { throw "Debug APK build failed" }

Write-Host "Checks passed. To run in an open Pixel_8a emulator:" -ForegroundColor Green
Write-Host 'flutter run -d emulator-5554'
