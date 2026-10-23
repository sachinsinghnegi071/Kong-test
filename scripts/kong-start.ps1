# Starts the local Kong AI Gateway container (e.g. after a laptop restart).
# Docker Desktop must be running first.
param([string]$ContainerName = "fervent_ardinghelli")

docker start $ContainerName
if ($LASTEXITCODE -ne 0) {
    Write-Host "Could not start '$ContainerName'. Is Docker Desktop running? Does the container exist (docker ps -a)?" -ForegroundColor Red
    exit 1
}
Write-Host "Started. Waiting 10 seconds for Kong to connect to Konnect..."
Start-Sleep -Seconds 10
docker ps --filter "name=^$ContainerName$" --format "{{.Names}} | {{.Status}} | {{.Ports}}"
