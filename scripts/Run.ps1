param([switch]$Server)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
if (-not $env:JAVA_HOME -or -not (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
    if (Test-Path "C:\Program Files\Java\jdk-24\bin\java.exe") {
        $env:JAVA_HOME = "C:\Program Files\Java\jdk-24"
    }
}
try {
    $classes = & "$PSScriptRoot\Build.ps1"
    $relClasses = Resolve-Path -LiteralPath $classes -Relative
    if ($Server) {
        & "$env:JAVA_HOME\bin\java.exe" '-Dfile.encoding=UTF-8' -cp "$relClasses;lib\mysql-connector-j.jar" server.ColorMatchServer
    } else {
        & "$env:JAVA_HOME\bin\java.exe" '-Dfile.encoding=UTF-8' -jar "dist\color-match-arena\ColorMatchArena-Client.jar"
    }
    exit $LASTEXITCODE
} catch { Write-Error $_; exit 1 }
