# Sends an OpenAI-style chat request through the local Kong AI Gateway and prints the reply.
# Check the exact path with the "Connect" button on the gateway page in Konnect, then pass -Path.
param(
    [string]$Url = "http://localhost:8000",
    [string]$Path = "/chat/completions",
    [string]$Model = "groq-llama",
    [string]$Message = "Say hello in one line",
    [string]$ApiKey = "",               # consumer key, only if an auth strategy is enabled
    [string]$ApiKeyHeader = "apikey"
)

$body = @{
    model    = $Model
    messages = @(@{ role = "user"; content = $Message })
} | ConvertTo-Json -Depth 5

$headers = @{ "Content-Type" = "application/json" }
if ($ApiKey) { $headers[$ApiKeyHeader] = $ApiKey }

$target = "$Url$Path"
Write-Host "POST $target  (model: $Model)" -ForegroundColor Cyan

try {
    $r = Invoke-WebRequest -Uri $target -Method Post -Headers $headers -Body $body -UseBasicParsing -TimeoutSec 60
    # Decode as UTF-8 explicitly; PowerShell 5.1 otherwise garbles characters like dashes
    $text = [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
    $json = $text | ConvertFrom-Json
    Write-Host "HTTP $($r.StatusCode)" -ForegroundColor Green
    if ($json.choices) {
        Write-Host "`nReply:" -ForegroundColor Green
        Write-Host $json.choices[0].message.content
        if ($json.usage) {
            Write-Host "`nTokens: prompt=$($json.usage.prompt_tokens) completion=$($json.usage.completion_tokens) total=$($json.usage.total_tokens)"
        }
    } else {
        $text
    }
} catch {
    if ($_.Exception.Response) {
        $code = [int]$_.Exception.Response.StatusCode
        Write-Host "HTTP $code" -ForegroundColor Red
        $msg = $_.ErrorDetails.Message
        if ($msg) { $msg }
        if ($msg -match "no Route matched") { Write-Host "No route for this path: create the model first, or check the path with the Connect button." -ForegroundColor Yellow }
        elseif ($msg -match "model_not_found") { Write-Host "Kong reached the LLM, but the provider does not know the target model. Change the target model in Konnect." -ForegroundColor Yellow }
        elseif ($msg -match "invalid_api_key") { Write-Host "Kong reached the LLM, but the key was rejected. Check the vault secret and the provider header value." -ForegroundColor Yellow }
    } else {
        Write-Host "No response: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Is Kong running? Try .\scripts\kong-status.ps1"
    }
    exit 1
}
