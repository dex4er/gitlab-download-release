#!/usr/bin/env pwsh

$env:CGO_ENABLED = "0"

## Read .env
if (Test-Path -Path ".env" -PathType Leaf) {
  Get-Content -Path ".env" | ForEach-Object {
    $key, $value = $_ -split '=', 2
    Set-Item -Path "env:$key" -Value $value
  }
}

# Parse command line arguments
$targets = @()
$currentTarget = ""

foreach ($arg in $args) {
  if ($arg -match '=') {
    ## Set variable
    $key, $value = $arg -split '=', 2
    Set-Item -Path "env:$key" -Value $value
  }
  else {
    ## Remember the target
    $targets += $arg
  }
}

$env:DOCKER = $env:DOCKER ?? "docker"
$env:GO = $env:GO ?? "go"
$env:GORELEASER = $env:GORELEASER ?? "goreleaser"

if ($env:OS -eq "Windows_NT") {
  $env:BIN = $env:BIN ?? "gitlab-download-release.exe"
  if ($env:LOCALAPPDATA) {
    $env:BINDIR = $env:BINDIR ?? "$env:LOCALAPPDATA\Microsoft\WindowsApps"
  }
  else {
    $env:BINDIR = $env:BINDIR ?? "C:\Windows\System32"
  }
}
else {
  $env:BIN = $env:BIN ?? "gitlab-download-release"
  if (Test-Path "$env:HOME\.local\bin") {
    $env:BINDIR = $env:BINDIR ?? "$env:HOME\.local\bin"
  }
  elseif (Test-Path "$env:HOME\bin") {
    $env:BINDIR = $env:BINDIR ?? "$env:HOME\bin"
  }
  else {
    $env:BINDIR = $env:BINDIR ?? "/usr/local/bin"
  }
}

function Get-Version {
  try {
    $exactMatch = git describe --tags --exact-match 2>$null
    if (-not [string]::IsNullOrEmpty($exactMatch)) { 
      $version = $exactMatch
    }
    else {
      $tags = git describe --tags 2>$null; 
      if ([string]::IsNullOrEmpty($tags)) { 
        $commitHash = (git rev-parse --short=8 HEAD).Trim();
        $version = "0.0.0-0-g$commitHash" 
      }
      else { 
        $version = $tags -replace '-[0-9][0-9]*-g', '-SNAPSHOT-' 
      }
    }
    $version = $version -replace '^v', ''
    return $version 
  }
  catch { 
    return "0.0.0" 
  }
}

function Get-Revision {
  $revision = git rev-parse HEAD
  return $revision
}

function Get-Builddate {
  $datetime = Get-Date
  $utc = $datetime.ToUniversalTime()
  return $utc.tostring("yyyy-MM-ddTHH:mm:ssZ")
}

$env:VERSION = $env:VERSION ?? (& get-version)
$env:REVISION = $env:REVISION ?? (& get-revision)
$env:BUILDDATE = $env:BUILDDATE ?? (& get-builddate)

function Invoke-CommandWithEcho {
  param (
    [string]$Command,
    [string[]]$Arguments
  )
  Write-Host $Command $Arguments
  $processInfo = Start-Process -FilePath $Command -ArgumentList $Arguments -PassThru
  $processInfo.WaitForExit()
  if ($processInfo.ExitCode -ne 0) {
    Write-Host "make: *** [$currentTarget] Error $($processInfo.ExitCode)"
    break
  }
}

function Invoke-ExpressionWithEcho {
  param (
    [string]$Command
  )
  Write-Host $Command
  Invoke-Expression -Command $Command
}

function Write-Target {
  param (
    [string]$Target
  )
  Write-Host "Executing target: $Target"
}

## TARGET build Build app binary for single target
function Invoke-Target-Build {
  Write-Target "build"
  Invoke-CommandWithEcho -Command $env:GO -Arguments "build", "-trimpath", "-ldflags=`"-s -w -X main.version=$env:VERSION`""
}

## TARGET goreleaser Build app binary for all targets
function Invoke-Target-Goreleaser {
  Write-Target "goreleaser"
  Invoke-CommandWithEcho -Command $env:GORELEASER -Arguments "release", "--auto-snapshot", "--clean", "--skip-publish"
}

## TARGET install Build and install app binary
function Invoke-Target-Install {
  if (-not (Test-Path -Path $env:BIN -PathType Leaf)) {
    Invoke-Target-Build
  }
  Write-Target "install"
  Invoke-ExpressionWithEcho -Command "Copy-Item -Path $env:BIN -Destination $env:BINDIR -Force"
}

## TARGET uninstall Uninstall app binary
function Invoke-Target-Uninstall {
  Write-Target "uninstall"
  $path = Join-Path $env:BINDIR $env:BIN
  Invoke-ExpressionWithEcho -Command "Remove-Item $path -Force"
}

## TARGET download Download Go modules
function Invoke-Target-Download {
  Write-Target "download"
  Invoke-CommandWithEcho -Command $env:GO -Arguments "mod", "download"
}

## TARGET tidy Tidy Go modules
function Invoke-Target-Tidy {
  Write-Target "tidy"
  Invoke-CommandWithEcho -Command $env:GO -Arguments "mod", "tidy"
}

## TARGET upgrade Upgrade Go modules
function Invoke-Target-Upgrade {
  Write-Target "upgrade"
  Invoke-CommandWithEcho -Command $env:GO -Arguments "get", "-u"
}

## TARGET clean Clean working directory
function Invoke-Target-Clean {
  Write-Target "clean"
  Invoke-ExpressionWithEcho -Command "Remove-Item dist -Recurse -Force -ErrorAction SilentlyContinue"
  Invoke-ExpressionWithEcho -Command "Remove-Item $env:BIN -Force -ErrorAction SilentlyContinue"
}

## TARGET version Show version
function Invoke-Target-Version {
  Write-Host $env:VERSION
}

## TARGET revision Show revision
function Invoke-Target-Revision {
  Write-Host $env:REVISION
}

## TARGET builddate Show build date
function Invoke-Target-Builddate {
  Write-Host $env:BUILDDATE
}

$env:DOCKERFILE = $env:DOCKERFILE ?? "Dockerfile"
$env:IMAGE_NAME = $env:IMAGE_NAME ?? "gitlab-download-release"
$env:LOCAL_REPO = $env:LOCAL_REPO ?? "localhost:5000/$env:IMAGE_NAME"
$env:DOCKER_REPO = $env:DOCKER_REPO ?? "localhost:5000/$env:IMAGE_NAME"

if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
  $env:PLATFORM = "linux/arm64"
}
elseif ((uname -m) -eq "arm64") {
  $env:PLATFORM = "linux/arm64"
}
elseif ((uname -m) -eq "aarch64") {
  $env:PLATFORM = "linux/arm64"
}
elseif ((uname -s) -match "ARM64") {
  $env:PLATFORM = "linux/arm64"
}
else {
  $env:PLATFORM = "linux/amd64"
}

## TARGET image Build a local image without publishing artifacts.
function Invoke-Target-Image {
  Write-Target "image"
  Invoke-CommandWithEcho -Command $env:DOCKER -Arguments "buildx", "build", "--file=$env:DOCKERFILE",
  "--platform=$env:PLATFORM",
  "--build-arg", "VERSION=$env:VERSION",
  "--build-arg", "REVISION=$env:REVISION",
  "--build-arg", "BUILDDATE=$env:BUILDDATE",
  "--tag", $env:LOCAL_REPO,
  "--load",
  "."
}

## TARGET push Publish to container registry.
function Invoke-Target-Push {
  Write-Target "push"
  Invoke-CommandWithEcho -Command $env:DOCKER -Arguments "tag", $env:LOCAL_REPO, "$($env:DOCKER_REPO):v$($env:VERSION)-$($env:PLATFORM -replace '/','-')"
  Invoke-CommandWithEcho -Command $env:DOCKER -Arguments "push", "$($env:DOCKER_REPO):v$($env:VERSION)-$($env:PLATFORM -replace '/','-')"
}

## TARGET test-image Test local image
function Invoke-Target-Test-Image {
  Write-Target "test-image"
  Invoke-CommandWithEcho -Command $env:DOCKER -Arguments "run", "--platform=$env:PLATFORM", "--rm", "-t", $env:LOCAL_REPO, "-v"
}

function Invoke-Target-Help {
  Write-Host "Targets:"
  Get-Content $PSCommandPath |
  Select-String '^## TARGET ' |
  Sort-Object |
  ForEach-Object {
    $target, $description = $_ -split ' ', 4 | Select-Object -Skip 2
    Write-Output ("  {0,-20} {1}" -f $target, $description)
  }
}

## Run target
if ($targets.Count -eq 0) {
  & Invoke-Target-Help
}
else {
  foreach ($target in $targets) {
    $currentTarget = $target
    Invoke-Expression ("Invoke-Target-" + $target)
  }
}
