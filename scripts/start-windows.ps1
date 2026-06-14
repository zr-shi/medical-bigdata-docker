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

$envPath = (Resolve-Path ".env").Path
$envContent = [System.IO.File]::ReadAllText($envPath)
$updatedEnvContent = $envContent.Replace(
    "shizr/medicine-bigdata:mysql-1.0.0",
    "shizr/medicine-bigdata:mysql-1.1.0"
).Replace(
    "shizr/medicine-bigdata:frontend-1.0.0",
    "shizr/medicine-bigdata:frontend-1.4.0"
).Replace(
    "shizr/medicine-bigdata:frontend-1.1.0",
    "shizr/medicine-bigdata:frontend-1.4.0"
).Replace(
    "shizr/medicine-bigdata:frontend-1.2.0",
    "shizr/medicine-bigdata:frontend-1.4.0"
).Replace(
    "shizr/medicine-bigdata:frontend-1.3.0",
    "shizr/medicine-bigdata:frontend-1.5.0"
).Replace(
    "shizr/medicine-bigdata:frontend-1.4.0",
    "shizr/medicine-bigdata:frontend-1.5.0"
).Replace(
    "shizr/medicine-bigdata:backend-1.0.0",
    "shizr/medicine-bigdata:backend-1.5.0"
).Replace(
    "shizr/medicine-bigdata:backend-1.2.0",
    "shizr/medicine-bigdata:backend-1.5.0"
).Replace(
    "shizr/medicine-bigdata:backend-1.3.0",
    "shizr/medicine-bigdata:backend-1.5.0"
).Replace(
    "shizr/medicine-bigdata:backend-1.4.0",
    "shizr/medicine-bigdata:backend-1.5.0"
)
if ($updatedEnvContent -ne $envContent) {
    [System.IO.File]::WriteAllText(
        $envPath,
        $updatedEnvContent,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Host "Updated public application images to version 1.5.0."
}

$profile = @()
if ($Full) {
    $profile = @("--profile", "bigdata")
}

& docker compose @profile pull
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& docker compose @profile up -d --no-build
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Startup failed. Recent backend and MySQL logs:"
    & docker compose logs --no-color --tail=80 backend mysql
    Write-Host ""
    Write-Host "If MySQL is healthy but the backend is unhealthy, an old Docker volume may use a different password."
    Write-Host "For an old local demo volume, set MYSQL_ROOT_PASSWORD=root123 in .env and run this script again."
    Write-Host "To discard all old demo data and start clean:"
    Write-Host "docker compose --profile bigdata down --volumes"
    exit $LASTEXITCODE
}

Write-Host "Applying safe database migrations..."
& docker compose exec -T mysql sh -c 'mysql --default-character-set=utf8mb4 -uroot -p"$MYSQL_ROOT_PASSWORD" his_system < /migrations/001_ensure_patient_cards.sql'
if ($LASTEXITCODE -ne 0) {
    Write-Host "Database migration failed. Recent MySQL logs:"
    & docker compose logs --no-color --tail=80 mysql
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Started. Open: http://localhost"
Write-Host "Username: admin"
Write-Host "Password: 123456"
if ($Full) {
    Write-Host "HDFS: http://localhost:9870"
    Write-Host "YARN: http://localhost:8088"
    Write-Host "Flink: http://localhost:8081"
}
