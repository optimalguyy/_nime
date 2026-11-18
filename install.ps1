# install.ps1 - set _nime up on Windows.
#
#   irm https://raw.githubusercontent.com/optimalguyy/_nime/master/install.ps1 | iex
#
# or, if you prefer a file you can read first:
#
#   iwr https://raw.githubusercontent.com/optimalguyy/_nime/master/install.ps1 -OutFile install.ps1
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#
# Nothing has to be installed beforehand. It uses winget (part of Windows 11 and
# current Windows 10) to install Git, which brings the shell _nime runs in, plus
# fzf, mpv, yt-dlp and ffmpeg, then puts _nime and a small launcher in
# %LOCALAPPDATA%\nime\bin and adds that to your PATH.

$ErrorActionPreference = 'Stop'

$repo   = 'https://raw.githubusercontent.com/optimalguyy/_nime/master'
$binDir = Join-Path $env:LOCALAPPDATA 'nime\bin'
$files  = @('_nime', '_nime-dl')
$packages = @(
    @{ Id = 'Git.Git';       Name = 'Git (the shell _nime runs in)' },
    @{ Id = 'junegunn.fzf';  Name = 'fzf (the picker)' },
    @{ Id = 'shinchiro.mpv'; Name = 'mpv (the player)' },
    @{ Id = 'yt-dlp.yt-dlp'; Name = 'yt-dlp (downloads)' },
    @{ Id = 'Gyan.FFmpeg';   Name = 'ffmpeg (downloads)' }
)

function Write-Step($text) { Write-Host "==> $text" -ForegroundColor Cyan }

function Find-Bash {
    foreach ($root in @($env:ProgramFiles, $env:LOCALAPPDATA) | Where-Object { $_ }) {
        foreach ($sub in @('Git\bin\bash.exe', 'Programs\Git\bin\bash.exe')) {
            $candidate = Join-Path $root $sub
            if (Test-Path $candidate) { return $candidate }
        }
    }
    $found = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    return $null
}

$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Host 'winget is missing, so the packages cannot be installed for you.' -ForegroundColor Yellow
    Write-Host 'Install "App Installer" from the Microsoft Store (or https://aka.ms/getwinget)'
    Write-Host 'and run this again. Nothing was changed.'
    exit 1
}

foreach ($pkg in $packages) {
    $there = $false
    try {
        $there = [bool](& $winget.Source list --id $pkg.Id --exact --accept-source-agreements 2>$null |
            Select-String -SimpleMatch $pkg.Id)
    } catch { }

    if ($there) {
        Write-Step "$($pkg.Name) is already there"
        continue
    }

    Write-Step "installing $($pkg.Name)"
    & $winget.Source install --id $pkg.Id --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    could not install $($pkg.Id), carrying on without it" -ForegroundColor Yellow
    }
}

# the installers changed PATH; rebuild it for this session
$machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPathNow = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$env:Path = "$machinePath;$userPathNow"

$bash = Find-Bash
if (-not $bash) {
    Write-Host 'Git was installed but bash.exe was not found yet.' -ForegroundColor Yellow
    Write-Host 'Open a new terminal and run this script once more.'
    exit 1
}

Write-Step "putting _nime in $binDir"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
foreach ($f in $files) {
    Invoke-WebRequest -Uri "$repo/$f" -OutFile (Join-Path $binDir $f) -UseBasicParsing
}

# C:\Users\you\AppData\Local\nime\bin\_nime  ->  C:/Users/you/AppData/Local/nime/bin/_nime
# bash takes a Windows path with forward slashes, so the launcher needs no
# quoting tricks to survive cmd: it hands bash the script and the arguments
$shBin = $binDir -replace '\\', '/'

foreach ($pair in @(@('nime.cmd', '_nime'), @('nime-dl.cmd', '_nime-dl'))) {
    $cmdFile = Join-Path $binDir $pair[0]
    $script  = $shBin + '/' + $pair[1]
    $lines = @(
        '@echo off'
        'setlocal'
        'set "BASH=' + $bash + '"'
        'if not exist "%BASH%" set "BASH=bash.exe"'
        '"%BASH%" "' + $script + '" %*'
    )
    Set-Content -Path $cmdFile -Value $lines -Encoding ASCII
}

$userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $userPath) { $userPath = '' }
if ($userPath -notlike "*$binDir*") {
    Write-Step "adding $binDir to your PATH"
    if ($userPath.TrimEnd(';') -eq '') { $newPath = $binDir }
    else { $newPath = $userPath.TrimEnd(';') + ';' + $binDir }
    [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
}

Write-Host ''
if (Test-Path (Join-Path $binDir '_nime')) {
    Write-Host 'done.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Open a new terminal so the PATH changes apply, then:'
    Write-Host '  nime cyberpunk' -ForegroundColor Cyan
    Write-Host '  nime -d -e 1 cyberpunk' -ForegroundColor Cyan
    Write-Host ''
    Write-Host "Downloads land in $env:USERPROFILE\Downloads\_nime downloads\<series>\."
} else {
    Write-Host "_nime was not written to $binDir" -ForegroundColor Yellow
    exit 1
}
