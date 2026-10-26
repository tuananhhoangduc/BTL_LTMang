param([switch]$Force)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$lock = New-Object System.Threading.Mutex($false, ('Local\ColorMatchBuild-' + ($projectRoot -replace '[^a-zA-Z0-9]', '_')))
$locked = $false
try {
    try { $locked = $lock.WaitOne(60000) } catch [System.Threading.AbandonedMutexException] { $locked = $true }
    if (-not $locked) { throw 'Another build is still running. Try again shortly.' }
    $jdk = $env:JAVA_HOME
    if (-not $jdk -or -not (Test-Path -LiteralPath "$jdk\bin\javac.exe")) {
        if (Test-Path -LiteralPath "C:\Program Files\Java\jdk-24\bin\javac.exe") {
            $jdk = "C:\Program Files\Java\jdk-24"
            $env:JAVA_HOME = $jdk
        } else {
            throw 'Set JAVA_HOME to a JDK 24 installation before building.'
        }
    }
    $sources = @(Get-ChildItem "common","client","server" -Filter *.java -File -Recurse | Sort-Object FullName)
    $inputs = @($sources) + @(Get-ChildItem "assets" -Recurse -File) + @(Get-Item $PSCommandPath)
    $hashText = ($inputs | Sort-Object FullName | Get-FileHash -Algorithm SHA256 | ForEach-Object Hash) -join ''
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $version = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($hashText)))).Replace('-','').Substring(0,16) }
    finally { $sha.Dispose() }
    $classes = "build\classes-$version"
    $package = 'dist\color-match-arena'
    $jar = Join-Path $package 'ColorMatchArena-Client.jar'
    $stamp = 'build\color-match-arena-package-version.txt'
    if ($Force -or -not (Test-Path -LiteralPath "$classes\.complete")) {
        New-Item -ItemType Directory -Path $classes -Force | Out-Null
        $sourcesFile = Join-Path $classes "sources.txt"
        @($sources | ForEach-Object { Resolve-Path -LiteralPath $_.FullName -Relative }) | Out-File -LiteralPath $sourcesFile -Encoding ascii
        & "$jdk\bin\javac.exe" --release 24 -encoding UTF-8 -cp "lib\mysql-connector-j.jar" -d $classes "@$sourcesFile"
        if ($LASTEXITCODE -ne 0) { throw 'Java compilation failed.' }
        Set-Content -LiteralPath "$classes\.complete" -Value $version -Encoding ASCII
    }
    if ($Force -or -not (Test-Path -LiteralPath $jar) -or -not (Test-Path -LiteralPath $stamp) -or (Get-Content $stamp -Raw).Trim() -ne $version) {
        New-Item -ItemType Directory -Path $package -Force | Out-Null
        $packageResources = "build\resources-$version"
        foreach ($asset in @(Get-ChildItem "assets" -Recurse -File)) {
            $relative = $asset.FullName.Substring((Get-Location).Path.Length + 1)
            if ($relative -eq 'assets\audio\ambient.wav' -or $relative -eq 'assets\HUONG_DAN_ASSET.txt') { continue }
            $destination = Join-Path $packageResources $relative
            New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $asset.FullName -Destination $destination -Force
        }
        & "$jdk\bin\jar.exe" --create --file $jar --main-class client.ClientApp -C $classes common -C $classes client -C $packageResources assets
        if ($LASTEXITCODE -ne 0) { throw 'Client packaging failed.' }
        Set-Content -LiteralPath $stamp -Value $version -Encoding ASCII
        Write-Host 'Built Color Match Arena client and server.'
    }
    return (Resolve-Path -LiteralPath $classes).Path
} finally {
    if ($locked) { $lock.ReleaseMutex() }
    $lock.Dispose()
}
