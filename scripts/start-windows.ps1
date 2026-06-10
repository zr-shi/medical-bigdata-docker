param(
    [switch]$Full
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker was not found. Install and start Docker Desktop first."
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Docker Desktop is not running. Start it and try again."
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env. Change its passwords before an Internet deployment."
}

$profile = @()
if ($Full) {
    $profile = @("--profile", "bigdata")
}

& docker compose @profile pull
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& docker compose @profile up -d --no-build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Started. Open: http://localhost"
Write-Host "Username: admin"
Write-Host "Password: 123456"
if ($Full) {
    Write-Host "HDFS: http://localhost:9870"
    Write-Host "YARN: http://localhost:8088"
    Write-Host "Flink: http://localhost:8081"
}
