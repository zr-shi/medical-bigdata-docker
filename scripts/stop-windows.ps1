param(
    [switch]$DeleteData
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if ($DeleteData) {
    docker compose --profile bigdata down --volumes
} else {
    docker compose --profile bigdata down
}

