param(
    [ValidateSet("dev", "staging", "prod")]
    [string]$Env = "dev",
    [string]$Tag = "local"
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$ports = @{ dev = 8091; staging = 8092; prod = 8093 }
$port = $ports[$Env]
$deployDir = Join-Path $root ".deploy"
New-Item -ItemType Directory -Path $deployDir -Force | Out-Null
$previousFile = Join-Path $deployDir "$Env.previous"
$previous = if (Test-Path $previousFile) { Get-Content $previousFile -Raw } else { "" }
$previous = $previous.Trim()
$Tag | Set-Content $previousFile

$image = "odsoft-lms:$Tag"
$env:LMS_IMAGE = $image

Write-Host "A construir o JAR..."
mvn -B -DskipTests package
if ($LASTEXITCODE -ne 0) { throw "Falha no mvn package" }

Write-Host "A construir $image..."
docker build -t $image .
if ($LASTEXITCODE -ne 0) { throw "Falha no docker build" }

Write-Host "A publicar $Env com $image..."
docker compose up -d "lms-$Env"
if ($LASTEXITCODE -ne 0) { throw "Falha no docker compose up" }

$healthy = $false
for ($i = 0; $i -lt 60; $i++) {
    try {
        Invoke-RestMethod -Uri "http://localhost:$port/actuator/health" -TimeoutSec 3 | Out-Null
        $healthy = $true
        break
    } catch {
        Start-Sleep -Seconds 2
    }
}

if (-not $healthy) {
    Write-Error "Deployment de $Env falhou no health check."
    if ($previous) {
        Write-Host "A reverter para $previous..."
        $env:LMS_IMAGE = "odsoft-lms:$previous"
        docker compose up -d "lms-$Env"
    }
    exit 1
}

Write-Host "DEPLOY_OK env=$Env image=$image"
