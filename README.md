# Obscura Examples

`obscura_examples` is a standalone Phoenix LiveView application which consumes
Obscura through its public API. It is executable documentation and an external
consumer contract test; it does not use Obscura evaluation modules, model
adapters, fixtures, or repository internals.

## Current Dependency

The application consumes the published Obscura package from Hex:

```elixir
{:obscura, "~> 0.1.2"}
```

`mix.lock` pins the resolved package release and checksum. Update Obscura
through the normal Hex dependency workflow.

## Run

The dependency-light `:fast` profile is ready immediately:

```sh
mix setup
mix phx.server
```

Open [http://localhost:4000](http://localhost:4000).

The app binds to loopback in development. It stores no input in a database or
filesystem, but LiveView process memory, BEAM memory, and explicitly displayed
results can contain submitted values. Use synthetic data.

## Workbench Coverage

| Workbench | Stable Obscura APIs exercised |
| --- | --- |
| Text | `Obscura.analyze/2`, `Obscura.redact/2`, all five stable operators |
| Structured | `Obscura.Structured.redact/2`, nested traversal, field policies |
| Vault & LLM | `Obscura.Vault.Memory`, pseudonymization, `Obscura.LLM`, direct and streaming rehydration |
| Logger & API | `Obscura.Logger`, `Obscura.Phoenix.Plug`, JSON request redaction |
| Profiles | `Obscura.Profile.describe/1`, preflight, explicit preparation, reusable runtimes |

The public contract test reads Obscura's shipped `public_api.exs` manifest and
fails when this app references a module which is not declared stable.

The Text workbench starts with the capability-aware **Common** entity preset.
**All** selects every entity supported by the active profile, **None** clears
the selection, and less common open-class entities remain under **Advanced
entities**. Changing profiles removes unsupported selections rather than
submitting an invalid entity list.

The Vault & LLM workbench creates a provider response locally for demonstration
and makes no network call. Pseudonymized values remain reversible while their
session-vault mappings exist; rehydrated output intentionally restores original
sensitive values. Detection misses and unconfigured entity types can remain in
all redacted or pseudonymized output.

## Model Profiles

The application installs `Nx` and `Bumblebee` so `:balanced` and `:accurate`
can be prepared explicitly. Ordinary page loading and `:fast` operations never
download models.

On macOS, Emily is installed automatically and is the default preparation
backend. Disable it explicitly when testing the portable Binary path:

```sh
OBSCURA_EXAMPLES_EMILY=0 mix deps.get
OBSCURA_EXAMPLES_EMILY=0 mix phx.server
```

On other platforms, set `OBSCURA_EXAMPLES_EMILY=1` only when Emily supports the
host and should be included.

On Linux with a supported NVIDIA GPU, install EXLA explicitly and target CUDA
before fetching and compiling dependencies. Match `XLA_TARGET` to the toolkit
reported by `nvcc --version`; use `cuda12` for CUDA 12.x and `cuda13` for CUDA
13.x:

```sh
export OBSCURA_EXAMPLES_EXLA=1
export XLA_TARGET=cuda13
export ELIXIR_ERL_OPTIONS="+sssdio 128"

mix deps.get
mix compile --warnings-as-errors
```

Keep `OBSCURA_EXAMPLES_EXLA=1` set for every Mix command in that build. When
switching an existing checkout back to the dependency-light configuration,
unset the variable and run `mix clean` before compiling again so a stale
application specification does not continue to reference EXLA.

Verify the host and EXLA runtime before preparing a model profile:

```sh
nvidia-smi
mix run -e 'IO.inspect(EXLA.Client.get_supported_platforms(), label: "EXLA platforms")'
mix run -e 'IO.inspect(EXLA.Client.fetch!(:cuda), label: "EXLA CUDA client")'
```

The checks must identify a CUDA platform and successfully fetch the `:cuda`
client. Loading the EXLA dependency alone is not evidence of GPU execution.
The `EXLA CUDA` workbench option is shown only when EXLA is installed; CUDA
availability must still be proven with these runtime checks and visible GPU
activity during inference.

The reproducible Tesla T4 validation, including CUDA 13 NVSHMEM compatibility
setup, exact detection evidence, and measured cold/warm latency, is documented
in [`docs/linux-nvidia-exla-validation.md`](docs/linux-nvidia-exla-validation.md).

In the Profiles workbench:

1. Select `Emily GPU` on Apple Silicon or `EXLA CUDA` on Linux/NVIDIA.
2. Review the machine-readable commercial-use notice shown for every external
   model asset.
3. Enable `Allow model downloads` only when the intended use is authorized and
   the disk requirements are acceptable.
4. Prepare `:balanced` or `:accurate` once.
5. Reuse the prepared runtime from the Text workbench for that LiveView
   session.

Without the Download option, preparation is cache-only. `:accurate` requires
two external model repositories and considerably more disk and memory than
`:balanced`. Obscura does not bundle or license these model assets. LDC directly
confirmed on 2026-07-22 that commercial use of the TNER checkpoint shared by
both profiles requires an LDC for-profit membership. Obscura does not grant or
verify that authorization. Use these profiles only for noncommercial evaluation
or deployments with the required LDC authorization.

The workbench reads this status from `Obscura.Capabilities` rather than
hard-coding profile rules. When an older Obscura release does not expose
machine-readable commercial-use metadata, the UI reports the status as
unavailable and does not imply commercial clearance.

The workbench identifies the Hugging Face repositories before preparation:

- `:balanced`: `tner/roberta-large-ontonotes5`, approximately 1.4 GB in the
  measured development cache;
- `:accurate`: that TNER model plus
  `Jean-Baptiste/roberta-large-ner-english`, approximately 2.8 GB total in the
  measured development cache.

These are approximate cache footprints, not guaranteed download sizes. The UI
shows the active Bumblebee cache destination, which honors
`BUMBLEBEE_CACHE_DIR`, and links directly to each model source. Emily requires
a supported Apple Silicon/macOS Metal GPU. Binary is the portable CPU path.
Preparation controls and both responsive profile layouts remain disabled while
a runtime is starting or loading, and duplicate submissions are ignored. The
selected backend and download permission remain visible throughout progress,
and an in-flight preparation can be cancelled. Public preflight diagnostics are
shown before preparation so missing dependencies, backends, tokenizers, or
assets include their remediation without requiring a speculative run.

The example intentionally keeps prepared runtimes in the connected LiveView
session. A production application should prepare shared runtimes under its
supervision tree with `Obscura.Profile.Preparer` and reuse them across requests.

## Plug API

The JSON endpoint runs `Obscura.Phoenix.Plug` in assign mode and returns only
the redacted copy. The workbench curl command calls this local example endpoint
and includes a clipboard action:

```sh
curl -X POST http://localhost:4000/api/redact \
  -H 'content-type: application/json' \
  -d '{"email":"rachel.green@example.com","phone":"+1 202-555-0188"}'
```

Expected response:

```json
{
  "data": {
    "email": "[EMAIL]",
    "phone": "[PHONE]"
  },
  "persisted": false,
  "profile": "fast"
}
```

## Validation

Run the consumer gate with:

```sh
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix assets.deploy
```

The suite covers:

- the canonical Git dependency and pinned commit;
- every stable anonymization operator;
- deterministic detection and offsets;
- structured redaction and field dropping;
- Logger-safe data and inspection;
- Plug request redaction;
- LiveView text, profile, vault, LLM, and streaming workflows;
- entity presets, capability filtering, mode-specific result contracts, and
  structured JSON error locations;
- explicit vault-clear confirmation and completion status;
- model preparation metadata and duplicate-preparation guards without loading
  model assets;
- enforcement of Obscura's stable API manifest.

Real model preparation and inference are intentionally opt-in because they
require external assets, backend-specific dependencies, substantial resources,
and asset-license review.

## Security Boundary

- No database, mailer, analytics service, or remote recognizer is configured.
- A vault is session-scoped and dies with its LiveView process.
- Clearing a vault removes accessible mappings but cannot guarantee memory
  zeroization.
- Assign-mode Plug redaction preserves original request fields inside the
  connection; the controller returns only the redacted assignment.
- Detection misses remain possible. This application is not a compliance
  certification or a universal secret detector.

## License

MIT. Obscura and every optional external model retain their own terms.
