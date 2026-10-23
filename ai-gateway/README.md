# AI Gateway as code (kongctl)

Create and update AI providers and models from `ai.yml` instead of the Konnect UI.

| File | Purpose |
|---|---|
| `ai.yml` | Providers + models (vault addresses only, never real keys) |

Tool: `tools/kongctl/kongctl.exe` (v1.20.2, checksum verified). Region: `in` (India).

## What is done where

| Task | Where | When |
|---|---|---|
| AI gateway (`ai-gateway-test`) | Konnect UI | Once |
| Data plane (Docker) | Konnect UI command + Docker | Once |
| Vault + secret (`konnectvault` / `groq-api-key` = `Bearer gsk_...`) | Konnect UI | Once per key |
| Providers + models | **`ai.yml` + scripts** | Every new AI API |

## Commands (PowerShell, from the KONG folder)

`kongctl` is on the user PATH (restart VS Code once so terminals pick it up).
Authenticate with a Konnect personal access token (Profile → Personal access tokens).
Add `--region in` to every command except login. Do not save the region in kongctl's
config file: it breaks browser login and token refresh.

```powershell
# Once per terminal: token stays only in this terminal session
$env:KONGCTL_DEFAULT_KONNECT_PAT = Read-Host "Paste Konnect token"

kongctl get ai-gateway --region in                               # check the token works

kongctl plan -f ai-gateway\ai.yml --mode apply --region in --output-file plan.json
kongctl diff --plan plan.json                                    # preview: + create, ~ change
kongctl apply -f ai-gateway\ai.yml --region in                   # create / update (never deletes)

kongctl dump declarative --resources=ai_gateways --include-child-resources --filter-name=ai-gateway-test --region in --output-file export.yaml   # read current setup

.\scripts\test-chat.ps1 -Model groq-cli-model                    # test a model through Kong
```

## Add a new AI API (model)

1. If it uses a new AI company: add its key to the vault in the UI, then add a provider block in `ai.yml`.
2. Copy a block under `models:` and change `ref`, `name`, `display_name`, and the target `name` / `provider`.
3. `kongctl plan ... --region in` + `kongctl diff ...` → check it shows only what you expect.
4. `kongctl apply -f ai-gateway\ai.yml --region in`
5. `.\scripts\test-chat.ps1 -Model <new-name>`

## Notes

- `kongctl apply` creates and updates, never deletes. Remove a model in the UI, or use `kongctl sync` (which also deletes) only when `ai.yml` is the full source of truth.
- `_external` in `ai.yml` points at the UI-created gateway, so kongctl manages only the providers and models listed in the file. The UI-made `groq` / `groq-llama` are not touched.
- Capability names: `generate` = Chat completions in the UI. Run `kongctl dump ...` after enabling other capabilities in the UI to see their names.
- Field reference: `kongctl explain ai_gateway_models --extended`
