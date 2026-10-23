# Stops the local Kong AI Gateway container. Config stays in Konnect; start again with kong-start.ps1.
param([string]$ContainerName = "fervent_ardinghelli")

docker stop $ContainerName
