param(
    [ValidateSet("dev", "staging", "prod")]
    [string]$Env = "dev"
)

$ErrorActionPreference = "Stop"
$ports = @{ dev = 8091; staging = 8092; prod = 8093 }
$url = "http://localhost:$($ports[$Env])/actuator/health"

Write-Host "A validar $Env em $url..."
for ($i = 0; $i -lt 30; $i++) {
    try {
        $response = Invoke-RestMethod -Uri $url -TimeoutSec 3
        $response | ConvertTo-Json -Depth 5
        Write-Host "SMOKE_OK env=$Env"
        exit 0
    } catch {
        Start-Sleep -Seconds 2
    }
}

Write-Error "SMOKE_FAILED env=$Env"
exit 1
