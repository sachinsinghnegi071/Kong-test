# Kong AI Gateway – Local Testing

Local test setup for routing AI (LLM) requests through Kong Konnect AI Gateway.
Kong runs on this laptop in Docker; Konnect (cloud) holds the config; Groq is the test LLM.

```
curl / app  →  Kong AI Gateway (Docker, localhost:8000)  →  Groq LLM
                       ▲ config            │ analytics
                       └──── Konnect (cloud, IN region) ◀┘
```

## Current setup

| Item | Value |
|---|---|
| Konnect org / region | CloudEQ / India (`cloud.konghq.com/in`) |
| AI gateway (control plane) | `ai-gateway-test` |
| Gateway product / version | Kong AI Gateway `2.2.0` (image `kong/kong-ai-gateway:2.2.0-distroless`) |
| Data plane | Docker container `fervent_ardinghelli` on this laptop |
| Gateway URL | `http://localhost:8000` (HTTPS: `https://localhost:8443`) |
| Vault | Konnect vault `konnectvault`, secret `groq-api-key` |
| Provider | `groq` (type OpenAI, header `Authorization: {vault://konnectvault/groq-api-key}`; the secret value is `Bearer gsk_...` because a vault reference must be the whole field value) |
| Model | display name `groq-llama` → target `openai/gpt-oss-20b` (Groq's Llama models need an enterprise plan) |
| Capability enabled | Chat completions (`/chat/completions`) |

## Folder contents

| Path | Purpose |
|---|---|
| `README.md` | This guide |
| `ai-gateway/ai.yml` | Providers + models as code (see `ai-gateway/README.md`) |
| `tools/kongctl/` | kongctl v1.20.2 (Kong CLI for AI Gateway), on the user PATH; use a Konnect token + `--region in` |
| `scripts/kong-status.ps1` | Is Kong running? Ports, health, last log lines |
| `scripts/kong-start.ps1` | Start the Kong container (after a laptop restart) |
| `scripts/kong-stop.ps1` | Stop the Kong container |
| `scripts/test-chat.ps1` | Send a chat request through Kong and print the reply |

## Steps done so far

1. Konnect account created (trial).
2. AI Gateway → New AI gateway → Self-managed → name `ai-gateway-test`.
3. Data plane setup → Docker → command from Konnect run in Git Bash → node Connected.
4. Vaults → New vault (Konnect) `konnectvault` → secret `groq-api-key` = Groq key.
5. Providers → Add provider `groq` (OpenAI type, auth provided by AI gateway).
6. Models → New → Model `groq-llama` → provider `groq`, target `llama-3.1-8b-instant`.

7. Model advanced fields: upstream URL `https://api.groq.com/openai/v1/chat/completions`, max tokens 1024, temperature 0.7.
   Capabilities: chat completions only. Routing: base path `/`.
8. Test passed on 2026-10-22: `POST /chat/completions` with `"model": "groq-llama"` → HTTP 200, reply from Groq.

9. Provider `groq-cli` + model `groq-cli-model` created from `ai-gateway/ai.yml` with kongctl → HTTP 200.

## Next steps

- [ ] Check **Overview → Analytics** for requests and tokens.
- [ ] Add a consumer + auth strategy, then test with `-ApiKey`.
- [ ] Add a policy (rate limit / prompt guard) and test it.
- [ ] Rotate the Groq key (it was shown in a screenshot) and update the vault secret as `Bearer gsk_...`.

## Lessons learned

- A vault reference must be the whole field value: `Bearer {vault://...}` is sent literally. Store `Bearer gsk_...` in the vault instead.
- Provider type OpenAI + a custom upstream URL works for any OpenAI-compatible LLM (Groq, vLLM, Ollama).
- Groq's Llama models need an enterprise plan; free accounts can use `openai/gpt-oss-20b`.
- Reasoning models (gpt-oss) spend tokens on thinking; keep max tokens at 1024 or more.

## Daily use (PowerShell, from this folder)

```powershell
# Is Kong up?
.\scripts\kong-status.ps1

# After a laptop restart (start Docker Desktop first)
.\scripts\kong-start.ps1

# Send a test chat request (update -Path after checking the Connect button)
.\scripts\test-chat.ps1
.\scripts\test-chat.ps1 -Message "What is an API gateway?" -Model groq-llama
.\scripts\test-chat.ps1 -Path "/chat/completions" -ApiKey "<consumer-key>"

# Stop Kong
.\scripts\kong-stop.ps1
```

If PowerShell blocks the scripts, run once per session:
`Set-ExecutionPolicy -Scope Process Bypass`

## What the responses mean

| Response | Meaning |
|---|---|
| `200` with a `choices` array | Working end to end |
| `404 no Route matched` | Model not created yet, or wrong path → check the Connect button |
| `401` from Kong | Auth strategy is on → pass `-ApiKey` |
| `401` / `invalid_api_key` from the LLM | Groq key wrong in the vault, or upstream still pointing to OpenAI |
| `could not resolve vault reference` | Vault name/secret key mismatch (`konnectvault` / `groq-api-key`) |
| `model not found` | Check the current model list at console.groq.com/docs/models |
| Connection refused | Kong not running → `.\scripts\kong-start.ps1` |

## Security notes

- The Groq key lives only in the Konnect vault — never put it in these files.
- The `docker run` command from Konnect contains a private key; it is not saved here.
  Re-generate the certificate in Konnect (Data plane nodes) if it was shared.
- For real clients, see the runbook: Step 3 (where the key lives) and Step 4 (where Kong runs).
