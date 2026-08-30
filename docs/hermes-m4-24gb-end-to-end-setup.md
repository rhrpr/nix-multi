# Hermes + ChatGPT/Codex + OpenRouter + LM Studio — End-to-End Setup Plan

**Target host:** MacBook Pro M4, 24 GB unified memory  
**Local inference:** LM Studio  
**Primary agent/orchestrator:** Hermes Agent  
**Primary frontier model path:** ChatGPT/Codex subscription via OAuth  
**Low-cost / local worker path:** LM Studio + a compact Qwen model  
**Paid overflow/specialist path:** OpenRouter  
**Claude:** optional/direct only where subscription/API entitlement supports it  
**Last verified against Hermes documentation:** 2026-08-30

---

## 1. Objective

Build a local-first Hermes setup that uses already-paid or zero-marginal-cost compute before consuming pay-as-you-go inference.

The intended cost hierarchy is:

```text
TIER 0 — LOCAL / £0 marginal token cost
MacBook Pro M4 + LM Studio
Qwen3.5-class ~9B model, quantized

  • context compression
  • title generation
  • triage/classification
  • log/config parsing
  • extraction/summarisation
  • simple code/repo investigation
  • vision where the local model supports it
  • delegated/subagent work

                │ task needs stronger reasoning
                ▼

TIER 1 — ALREADY SUBSCRIBED
ChatGPT/Codex OAuth

  • main Hermes conversation
  • planning and synthesis
  • architecture
  • difficult coding/debugging
  • final decision making

                │ specialist / second opinion / overflow
                ▼

TIER 2 — PAYG
OpenRouter

  • specialist models
  • alternate-model review
  • cloud fallback
  • Gemini / DeepSeek / Kimi / Claude when explicitly justified

                │ exceptional high-value use
                ▼

TIER 3 — PREMIUM FRONTIER
Claude or another expensive frontier model

  • difficult architecture critique
  • independent high-quality review
  • tasks where the added capability is worth API/overage cost
```

Hermes should be the orchestration layer. OpenRouter should **not** be placed in front of everything by default, because that would turn already-paid ChatGPT usage and local M4 compute into unnecessary PAYG traffic.

---

## 2. Desired architecture

```text
                           HERMES
                              │
                main planning │
                              ▼
                    ChatGPT / Codex OAuth
                    subscription-backed
                              │
             ┌────────────────┴────────────────┐
             │                                 │
       auxiliary work                    failure/specialist
             │                                 │
             ▼                                 ▼
       LM Studio / M4                      OpenRouter
       local model                         PAYG only
             │                                 │
     ┌───────┼────────┐               ┌────────┼─────────┐
     │       │        │               │        │         │
 compression titles  subagents      Gemini  Claude   other models
 triage      vision  simple code
 summaries          repo analysis
```

Important routing rule:

- `fallback_providers` is **failure handling**, not intelligent complexity routing.
- Cost optimisation should primarily come from Hermes' `auxiliary.*` routing and `delegation` routing.
- The main model remains Codex unless deliberately switched.

---

## 3. 24 GB M4 local-model strategy

### Recommended default

Use a **Qwen3.5-class 9B model, MLX 4-bit**, or the nearest currently available equivalent with:

- strong instruction following;
- tool calling;
- preferably vision support;
- at least 64K usable context;
- good MLX performance on Apple Silicon.

Do **not** optimise for the largest model that can technically be made to load.

On a 24 GB machine, the better agent worker is usually:

```text
9B model + 64K context + healthy memory pressure + good throughput
```

rather than:

```text
20B–30B model + insufficient context/headroom + swap + poor latency
```

### Initial concurrency

Start with:

```yaml
max_concurrent_children: 1
max_spawn_depth: 1
```

After observing memory pressure and token throughput, test `max_concurrent_children: 2`.

Do not start with recursive/nested local agent trees on 24 GB.

### Context length

Use **64,000 tokens** initially.

Even where the model advertises a much larger context window, 64K is the target because Hermes recommends at least 64K for smooth local agent usage while the KV cache remains manageable on a 24 GB machine.

---

## 4. Install / expose LM Studio

LM Studio is already installed, but its CLI and local server should be available.

### Install the `lms` CLI if required

```bash
npx lmstudio install-cli
```

Restart the shell if needed.

### Inspect installed models

```bash
lms ls
```

Select/install a suitable MLX 4-bit ~9B Qwen model in the LM Studio GUI if not already present.

### Estimate memory before loading at 64K

Replace `<LOCAL_MODEL_ID>` with the exact LM Studio model ID:

```bash
lms load <LOCAL_MODEL_ID> \
  --context-length 64000 \
  --estimate-only
```

If the estimate is comfortable:

```bash
lms load <LOCAL_MODEL_ID> \
  --context-length 64000
```

### Start the LM Studio API server

```bash
lms server start
```

LM Studio normally exposes its OpenAI-compatible API at:

```text
http://localhost:1234/v1
```

### Verify model discovery

```bash
curl -s http://localhost:1234/v1/models | jq
```

For a clean model-ID list:

```bash
curl -s http://localhost:1234/v1/models | jq -r '.data[].id'
```

Record the exact model ID. Do not guess it in the Hermes configuration.

---

## 5. Enable LM Studio JIT loading / Auto-Evict

For a laptop, prefer LM Studio's JIT loading / Auto-Evict behavior so the model does not occupy unified memory permanently.

Once Hermes is installed:

```bash
hermes config set model.lmstudio_load_mode jit
```

Enable the corresponding JIT/Auto-Evict behavior in LM Studio.

Expected behavior:

```text
normal Mac use
    │
    ├─ model need not remain loaded
    │
Hermes invokes local auxiliary/subagent work
    │
    ▼
LM Studio loads model
    │
    ▼
work completes
    │
    ▼
model can later be evicted
```

If JIT behavior becomes unreliable, revert Hermes to explicit loading:

```bash
hermes config set model.lmstudio_load_mode explicit
```

---

## 6. Install Hermes Agent

Use the current official Hermes install path or package it through nix-darwin if the package/version is reproducible there.

Manual/bootstrap form:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

Reload shell configuration as needed, then validate:

```bash
hermes --help
hermes doctor
hermes status
```

### Hermes state locations

Expect user-specific state under:

```text
~/.hermes/config.yaml
~/.hermes/.env
~/.hermes/auth.json
```

The declarative nix-darwin layer should manage **configuration**, not bake OAuth refresh tokens or API keys into the Nix store.

---

## 7. Authenticate ChatGPT/Codex as the main provider

Run:

```bash
hermes model
```

Choose the **ChatGPT or Codex Subscription** provider and complete its OAuth/device-code login.

Hermes' canonical provider ID for the main model is:

```text
openai-codex
```

OAuth credentials are stored in Hermes' auth store rather than as a normal OpenAI API key.

A standalone Codex CLI session is separate and may use:

```text
~/.codex/auth.json
```

If the Codex CLI is also desired:

```bash
npm i -g @openai/codex
codex login
```

The Hermes-managed Codex OAuth and the standalone Codex CLI OAuth should be treated as separate auth sessions unless current tooling explicitly imports/reuses one.

### Main-model rule

After adding other providers, return to:

```bash
hermes model
```

and ensure the **main Hermes model is still the desired Codex model**.

Do not hard-code an assumed Codex model ID before checking the model list exposed to the account at setup time.

---

## 8. Add OpenRouter

Create an OpenRouter API key and register it through:

```bash
hermes model
```

or securely expose:

```bash
OPENROUTER_API_KEY=...
```

Hermes commonly reads secrets from:

```text
~/.hermes/.env
```

If that file is used directly:

```bash
chmod 600 ~/.hermes/.env
```

Do **not** put the actual OpenRouter key directly in a world-readable nix-darwin module or in a derivation that lands in `/nix/store`.

Preferred Nix integration options include:

- `sops-nix`;
- `agenix`;
- Keychain-backed secret injection;
- a protected user environment file generated outside the Nix store.

---

## 9. Register LM Studio with Hermes

With the LM Studio API server running:

```bash
hermes model
```

Choose:

```text
LM Studio
```

Use the default endpoint where appropriate:

```text
http://localhost:1234/v1
```

Hermes has a first-class `lmstudio` provider, and can discover models exposed by LM Studio.

Select the local model once to validate the provider, then switch the main model back to Codex.

---

## 10. Recommended Hermes configuration

### Important integration rule

Let `hermes model` generate/maintain the **main `model:` block** for Codex OAuth rather than inventing an OAuth-backed model stanza manually.

The following is intended to be merged around the generated main-model configuration.

Replace every `<LOCAL_MODEL_ID>` with the exact value returned from:

```bash
curl -s http://localhost:1234/v1/models | jq -r '.data[].id'
```

### Configuration

```yaml
# ~/.hermes/config.yaml
#
# Keep the `model:` section generated by `hermes model` for
# ChatGPT/Codex OAuth. Do not blindly overwrite it.

# ----------------------------------------------------------
# OPENROUTER ROUTING POLICY
# Applies when requests actually go through OpenRouter.
# ----------------------------------------------------------
provider_routing:
  sort: "price"
  data_collection: "deny"


# ----------------------------------------------------------
# LOCAL AUXILIARY TASKS
# Cheap/background model work goes to LM Studio.
# ----------------------------------------------------------
auxiliary:
  # Protect a 24 GB laptop from multiple simultaneous helper
  # generations until real memory pressure has been measured.
  max_concurrency: 1

  compression:
    base_url: "http://localhost:1234/v1"
    api_key: "local-key"
    model: "<LOCAL_MODEL_ID>"
    timeout: 180
    fallback_chain:
      - provider: "main"

  title_generation:
    enabled: true
    base_url: "http://localhost:1234/v1"
    api_key: "local-key"
    model: "<LOCAL_MODEL_ID>"
    timeout: 60
    fallback_chain:
      - provider: "main"

  approval:
    base_url: "http://localhost:1234/v1"
    api_key: "local-key"
    model: "<LOCAL_MODEL_ID>"
    timeout: 60
    fallback_chain:
      - provider: "main"

  triage_specifier:
    base_url: "http://localhost:1234/v1"
    api_key: "local-key"
    model: "<LOCAL_MODEL_ID>"
    timeout: 120
    fallback_chain:
      - provider: "main"

  skills_hub:
    base_url: "http://localhost:1234/v1"
    api_key: "local-key"
    model: "<LOCAL_MODEL_ID>"
    timeout: 60
    fallback_chain:
      - provider: "main"

  mcp:
    base_url: "http://localhost:1234/v1"
    api_key: "local-key"
    model: "<LOCAL_MODEL_ID>"
    timeout: 60
    fallback_chain:
      - provider: "main"

  # Enable this only if the chosen local model has suitable vision
  # capability and LM Studio exposes it correctly.
  vision:
    base_url: "http://localhost:1234/v1"
    api_key: "local-key"
    model: "<LOCAL_MODEL_ID>"
    timeout: 180
    fallback_chain:
      - provider: "main"


# ----------------------------------------------------------
# LOCAL SUBAGENTS
# Codex plans; local Qwen workers perform delegated work.
# ----------------------------------------------------------
delegation:
  model: "<LOCAL_MODEL_ID>"
  base_url: "http://localhost:1234/v1"
  api_key: "local-key"
  api_mode: "chat_completions"

  # Conservative defaults for a 24 GB unified-memory machine.
  max_concurrent_children: 1
  max_spawn_depth: 1
  orchestrator_enabled: false

  # Optional: protect against unexpectedly long local agent loops.
  max_iterations: 30


# ----------------------------------------------------------
# MAIN MODEL FAILURE FALLBACK
# This is availability failover, NOT cheap-task routing.
# ----------------------------------------------------------
fallback_providers:
  # First attempt local inference if the main provider fails.
  - provider: "lmstudio"
    model: "<LOCAL_MODEL_ID>"

  # Final paid cloud fallback.
  # Choose/update this explicitly based on current OpenRouter
  # catalogue, price, and capability.
  - provider: "openrouter"
    model: "<OPENROUTER_FALLBACK_MODEL>"
```

### Notes on this configuration

1. `auxiliary.<task>.base_url` directs that task straight to LM Studio.
2. Each auxiliary task has a `fallback_chain` back to the main model for availability resilience.
3. `delegation.base_url` takes precedence and sends all Hermes delegated children to the local OpenAI-compatible endpoint.
4. `max_spawn_depth: 1` prevents delegated workers from recursively spawning more workers.
5. `orchestrator_enabled: false` deliberately keeps the local-worker topology flat while the machine is being tuned.
6. Main `fallback_providers` activates when the main model/provider fails; it does not inspect task difficulty.
7. OpenRouter provider routing settings only affect traffic that actually travels through OpenRouter.

---

## 11. Why auxiliary + delegation routing matters more than fallbacks

This is the intended normal path:

```text
User asks complex question
       │
       ▼
Codex main agent
       │
       ├─ plans task
       │
       ├─ delegates mechanical/research/code-inspection work
       │          │
       │          ▼
       │      local Qwen / M4
       │          │
       │          ▼
       │      compact result
       │
       ▼
Codex performs final synthesis
```

This is the fallback path:

```text
Codex provider failure / rate limit / connectivity/auth issue
       │
       ▼
LM Studio fallback
       │
       ▼ if unavailable/unsuitable
OpenRouter fallback
```

Do not confuse the two.

---

## 12. Suggested work assignment

### Local model

Push the following toward the M4 worker wherever practical:

- conversation titles;
- summarisation;
- context compression;
- classifications;
- extracting structured information;
- parsing logs/manifests/configuration;
- searching/understanding small parts of a repository;
- straightforward test generation;
- simple configuration/code review;
- parallel research subtasks;
- image/screenshot understanding if the selected local model's vision support works correctly.

### Codex main model

Reserve the subscription-backed main model for:

- planning;
- architecture;
- cross-system reasoning;
- difficult debugging;
- complex code changes;
- deciding between conflicting subagent findings;
- final synthesis and answer generation.

### OpenRouter

Use PAYG primarily for:

- explicit alternate-model opinions;
- specialist model access;
- cloud overflow;
- a model family not otherwise available;
- emergency fallback from the primary + local path.

### Claude

Treat Claude as optional rather than part of the default automatic route.

Current Hermes documentation indicates Anthropic can be used via API credentials, while subscription/OAuth entitlement depends on the Anthropic plan and any extra-usage arrangement. Do not assume a normal Claude subscription automatically provides free Hermes inference.

Where Claude is desired occasionally, OpenRouter can be used explicitly and billed PAYG.

---

## 13. Nix-darwin integration boundaries

The separate Nix agent should split this into **declarative machine state** and **runtime/user-secret state**.

### Good candidates for declarative nix-darwin/Home Manager management

- Hermes executable/package installation;
- LM Studio CLI availability if packageable;
- `jq`;
- Node/npm only if required for LM Studio/Codex bootstrap;
- Codex CLI package if desired;
- `~/.hermes/config.yaml` template;
- shell PATH;
- launch agents/services for optional LM Studio server startup;
- file permissions;
- helper scripts such as `hermes-local-health`;
- environment-variable *names*/paths, but not plaintext secret values;
- pinned versions or hashes where practical.

### Keep outside the public Nix store

Never declaratively embed plaintext:

- `OPENROUTER_API_KEY`;
- Anthropic API keys;
- OAuth refresh/access tokens;
- `~/.hermes/auth.json` contents;
- `~/.codex/auth.json` contents.

Use a secret manager or mutable user-owned credential files instead.

### Suggested generated layout

```text
~/.config/nix-darwin/
  modules/
    hermes.nix
    lm-studio.nix
    secrets.nix            # references secret material, not plaintext

~/.hermes/
  config.yaml              # declaratively generated/linked
  .env                     # secret-managed / mutable
  auth.json                # generated by OAuth flow / mutable

~/.codex/
  auth.json                # generated by codex login / mutable
```

### Important OAuth rule for declarative builds

Do not try to make OAuth login itself purely declarative.

A sensible lifecycle is:

```text
nix-darwin rebuild
       │
       ▼
packages + config installed
       │
       ▼
one-time / occasional mutable auth step
       │
       ├─ hermes model / hermes auth ...
       └─ codex login (if Codex CLI runtime is used)
```

---

## 14. Optional launchd behavior

Do not automatically force the large local model to remain loaded on boot.

A better default for a laptop is:

1. optionally start only the LM Studio API server;
2. enable JIT model loading / Auto-Evict;
3. let Hermes create local inference demand.

If a launch agent is created for LM Studio's server, make it restartable and ensure Hermes continues to function through its configured fallback chain if the local service is absent.

---

## 15. Validation checklist

### A. LM Studio

```bash
lms ls
lms server start
curl -s http://localhost:1234/v1/models | jq
```

Expected:

- server reachable;
- selected local model visible;
- model can run with 64K context;
- no severe macOS memory pressure.

### B. Hermes

```bash
hermes doctor
hermes status
hermes config get model --json
```

Expected:

- main provider/model shows the intended Codex configuration;
- OpenRouter credentials are recognised;
- LM Studio is reachable.

### C. Auxiliary routing test

Start Hermes and run a simple request likely to trigger helper activity.

Observe LM Studio's server logs and confirm local requests arrive.

### D. Delegation routing test

Use a deliberately separable task, for example:

```text
Analyse this repository. Delegate independent investigation of:
1. architecture,
2. dependencies,
3. CI/CD configuration,
and then synthesize the findings.
```

Observe that delegated inference goes to `localhost:1234` while the main planning/synthesis remains on Codex.

### E. Failure fallback test

Only after the normal path works, deliberately make the main provider unavailable or test using Hermes' supported fallback management/testing flow.

Confirm the chain behaves as intended:

```text
Codex → LM Studio → OpenRouter
```

Do not test by deleting OAuth/token files without a backup.

---

## 16. Performance-tuning sequence for the 24 GB Mac

Tune in this order rather than changing several variables simultaneously.

### Phase 1 — baseline

```yaml
auxiliary:
  max_concurrency: 1

delegation:
  max_concurrent_children: 1
  max_spawn_depth: 1
  orchestrator_enabled: false
```

Run realistic workloads and inspect:

- Activity Monitor memory pressure;
- swap usage;
- LM Studio tokens/sec;
- time to first token;
- Hermes local-task reliability.

### Phase 2 — allow two local children

If memory pressure remains green and throughput is acceptable:

```yaml
delegation:
  max_concurrent_children: 2
```

Retest with two genuinely concurrent delegated tasks.

### Phase 3 — optional larger worker model

Only after the 9B worker is stable, benchmark a 12B/14B-class MLX 4-bit model.

Do not replace the 9B model merely because the larger model fits. Compare:

- tokens/sec;
- tool-call reliability;
- quality on representative delegated work;
- 64K context memory cost;
- swap pressure;
- battery/thermal impact.

The 9B model should remain the default if its total agent throughput is better.

---

## 17. Possible future improvement: two local profiles

If LM Studio JIT switching works well, a later design could expose two local models rather than loading both simultaneously:

```text
FAST LOCAL
~4B–9B model
  • titles
  • classification
  • extraction
  • compression

STRONG LOCAL
~9B–14B model
  • delegated coding
  • repository analysis
  • deeper summaries/reasoning
```

However, Hermes' global delegation model pin means the simplest first version is a single capable ~9B worker for all delegated work.

Avoid adding routing complexity until the baseline is measured.

---

## 18. Optional Codex app-server runtime

Hermes also supports an optional Codex app-server runtime where OpenAI/Codex turns execute through the Codex CLI runtime/tool loop.

Treat this as a **second-stage experiment**, not a prerequisite for the initial architecture.

If enabled later:

```bash
npm i -g @openai/codex
codex login
```

Then follow current Hermes documentation for enabling its Codex app-server runtime.

Keep local `auxiliary.*` overrides in place if the goal is to prevent helper tasks from unnecessarily consuming subscription-backed Codex turns.

---

## 19. Security principles

1. No API keys in Git.
2. No OAuth refresh tokens in Git.
3. Avoid secrets entering `/nix/store`.
4. Keep `~/.hermes/.env`, `~/.hermes/auth.json`, and `~/.codex/auth.json` appropriately permissioned.
5. Prefer local inference for private mechanical processing where quality is sufficient.
6. Do not expose LM Studio's API server beyond localhost unless there is a deliberate authentication/networking design.
7. Keep the OpenRouter `data_collection: "deny"` preference where compatible with the selected providers/models.
8. Review provider-specific privacy/data-retention behavior before routing sensitive material to any PAYG model.

---

## 20. Build order for the Nix implementation agent

Implement in this order:

```text
1. Package/install prerequisites
   ├─ Hermes
   ├─ jq
   ├─ LM Studio CLI integration
   └─ optional Codex CLI

2. Make LM Studio server reachable
   └─ localhost:1234/v1

3. Establish selected local model + 64K profile

4. Generate ~/.hermes/config.yaml
   ├─ preserve/generated Codex main model section
   ├─ local auxiliary routes
   ├─ local delegation route
   ├─ fallback chain
   └─ OpenRouter routing policy

5. Add secret-management integration
   └─ OpenRouter/API credentials outside Nix store

6. nix-darwin rebuild

7. Perform mutable OAuth setup
   ├─ Hermes Codex OAuth
   └─ optional standalone Codex CLI OAuth

8. Validate local inference

9. Validate auxiliary inference

10. Validate delegated work

11. Validate paid fallback

12. Benchmark concurrency = 1 vs 2
```

---

## 21. Acceptance criteria

The setup is complete when all of the following are true:

- [ ] `hermes doctor` passes with no material provider/config problems.
- [ ] Hermes' main provider is ChatGPT/Codex subscription OAuth.
- [ ] LM Studio API responds at `localhost:1234/v1`.
- [ ] Local ~9B model operates with a 64K context without unhealthy swap/memory pressure.
- [ ] Hermes auxiliary tasks visibly hit LM Studio.
- [ ] Hermes delegated subagents visibly hit LM Studio.
- [ ] Normal main-agent reasoning stays on Codex.
- [ ] OpenRouter exists as a configured paid escape hatch rather than the default path.
- [ ] Main-provider failure can fail over to LM Studio and then OpenRouter.
- [ ] API keys and OAuth credentials are absent from Git and the public Nix store.
- [ ] JIT/Auto-Evict prevents the local model needlessly monopolising RAM during ordinary laptop use.
- [ ] Local concurrency has been benchmarked at 1 and optionally 2 before increasing it.

---

## 22. Source documentation

Use these as the canonical references when the Nix agent encounters a version-specific configuration difference:

- Hermes AI / LLM providers:  
  https://hermes-agent.nousresearch.com/docs/integrations/providers

- Hermes configuration reference:  
  https://hermes-agent.nousresearch.com/docs/user-guide/configuration/

- Hermes fallback providers:  
  https://hermes-agent.nousresearch.com/docs/user-guide/features/fallback-providers/

- Hermes subagent delegation:  
  https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation

- Hermes provider routing / OpenRouter routing:  
  https://hermes-agent.nousresearch.com/docs/user-guide/features/provider-routing

- Hermes CLI command reference (`hermes model` etc.):  
  https://hermes-agent.nousresearch.com/docs/reference/cli-commands/

- Hermes Codex app-server runtime (optional):  
  https://hermes-agent.nousresearch.com/docs/user-guide/features/codex-app-server-runtime

- LM Studio:  
  https://lmstudio.ai/

---

## 23. Key instruction for the implementation agent

**Do not blindly replace `~/.hermes/config.yaml` with the sample above.**

First allow Hermes' current `hermes model` flow to establish the real Codex OAuth-backed `model:` block and discover the exact local LM Studio model ID. Then merge the declarative auxiliary/delegation/fallback settings around those runtime-discovered values.

The desired end state is:

```text
Hermes = orchestration and memory/tool layer
Codex  = main planner/reasoner using the existing ChatGPT subscription
M4     = token-heavy local worker fleet using LM Studio
OpenRouter = PAYG fallback/specialist model marketplace
Claude = explicit specialist path only where entitlement/cost makes sense
```

This deliberately minimises incremental inference spend while retaining frontier-model quality for the tasks that actually need it.
