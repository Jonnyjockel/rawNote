# build.ps1 — build rawNote (100% x86-64 assembly) into a single .exe
# Requires Visual Studio 2022 with MSVC x64 tools (ml64.exe + link.exe).
# Usage:
#   .\build.ps1          -> assemble + link -> build\rawNote.exe
#   .\build.ps1 -Clean   -> remove build output
param([switch]$Clean)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Src  = Join-Path $Root 'src'
$Out  = Join-Path $Root 'build'

if ($Clean) {
    if (Test-Path $Out) { Remove-Item -Recurse -Force $Out }
    Write-Host 'build/ removed.' -ForegroundColor Yellow
    exit 0
}

# Locate Visual Studio + vcvars64.bat
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { throw 'vswhere not found — is Visual Studio installed?' }
$vsPath = & $vswhere -latest -products * -property installationPath
if (-not $vsPath) { throw 'No Visual Studio install found.' }
$vcvars = Join-Path $vsPath 'VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path $vcvars)) { throw "vcvars64.bat not found under $vsPath" }

# Pull the VS dev environment into this PowerShell session.
$envLines = cmd /c "`"$vcvars`" >nul 2>&1 && set"
foreach ($line in $envLines) {
    if ($line -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

New-Item -ItemType Directory -Force -Path $Out | Out-Null

# Compile icon resource
$pf86 = ${env:ProgramFiles(x86)}
$rc = Get-ChildItem -Recurse -Filter 'rc.exe' "$pf86\Windows Kits\10\bin" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like '*\x64\rc.exe' } | Sort-Object FullName -Descending | Select-Object -First 1
if ($rc) {
    $um = Get-ChildItem -Directory "$pf86\Windows Kits\10\Include" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    $inc = "$($um.FullName)\um;$($um.FullName)\shared"
    Write-Host "Compiling rawNote.rc -> rawNote.res" -ForegroundColor Cyan
    & $rc.FullName /nologo /fo"$Out\rawNote.res" /i"$inc" "$Src\rawNote.rc"
    if ($LASTEXITCODE -ne 0) { throw 'rc failed' }
}

Write-Host "Assembling rawNote.asm -> rawNote.obj" -ForegroundColor Cyan
& ml64 /c /nologo /Fo"$Out\rawNote.obj" "$Src\rawNote.asm"
if ($LASTEXITCODE -ne 0) { throw 'ml64 failed' }

Write-Host "Linking -> rawNote.exe" -ForegroundColor Cyan
& link /nologo /subsystem:windows /entry:start "$Out\rawNote.obj" `
    kernel32.lib user32.lib gdi32.lib shell32.lib comctl32.lib `
    "$Out\rawNote.res" `
    /out:"$Out\rawNote.exe"
if ($LASTEXITCODE -ne 0) { throw 'link failed' }

Write-Host "Built $Out\rawNote.exe" -ForegroundColor Green
