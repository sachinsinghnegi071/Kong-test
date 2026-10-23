# Loads KEY=VALUE lines from .env into the current terminal's environment variables.
# Run it with a leading dot so the variables stay in your terminal:
#   . .\scripts\load-env.ps1
param([string]$File = (Join-Path (Split-Path $PSScriptRoot -Parent) ".env"))

if (-not (Test-Path $File)) {
    Write-Host "No .env file found at $File. Copy .env.example to .env and fill it in." -ForegroundColor Red
    return
}

$names = @()
foreach ($line in Get-Content $File) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith("#") -or -not $line.Contains("=")) { continue }
    $name, $value = $line.Split("=", 2)
    Set-Item -Path "Env:$($name.Trim())" -Value $value.Trim().Trim('"')
    $names += $name.Trim()
}
# Print only the names, never the values
Write-Host "Loaded: $($names -join ', ')" -ForegroundColor Green
