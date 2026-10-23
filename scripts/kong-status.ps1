# Shows whether the local Kong AI Gateway container is running and responding.
param(
    [string]$ContainerName = "fervent_ardinghelli",
    [string]$Url = "http://localhost:8000"
)

Write-Host "== Container ==" -ForegroundColor Cyan
docker ps -a --filter "name=^$ContainerName$" --format "Name: {{.Names}}`nStatus: {{.Status}}`nImage: {{.Image}}`nPorts: {{.Ports}}"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not reachable. Start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

Write-Host "`n== Gateway response ($Url) ==" -ForegroundColor Cyan
try {
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
    Write-Host "HTTP $($r.StatusCode)  Server: $($r.Headers['Server'])"
} catch {
    if ($_.Exception.Response) {
        $code = [int]$_.Exception.Response.StatusCode
        $server = $_.Exception.Response.Headers['Server']
        Write-Host "HTTP $code  Server: $server"
        if ($code -eq 404) { Write-Host "Kong is up (404 = no route on '/', which is expected)." -ForegroundColor Green }
    } else {
        Write-Host "No response: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n== Last 10 log lines ==" -ForegroundColor Cyan
# cmd /c keeps PowerShell 5.1 from showing docker's stderr log lines as errors
cmd /c "docker logs --tail 10 $ContainerName 2>&1"
