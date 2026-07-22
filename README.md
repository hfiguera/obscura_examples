# Obscura Examples

`obscura_examples` is a standalone Phoenix LiveView application which consumes
Obscura through its public API. It is executable documentation and an external
consumer contract test; it does not use Obscura evaluation modules, model
adapters, fixtures, or repository internals.

## Current Dependency

Obscura has not been published to Hex and its canonical repository is private.
The application therefore uses the authenticated SSH repository URL and tracks
`main`:

```elixir
{:obscura, git: "git@github.com:hfiguera/obscura.git", branch: "main"}
```

`mix.lock` pins an exact Obscura commit. Run `mix deps.update obscura` when this
application should validate a newer `main` revision.

Once the repository is public, replace the dependency with the anonymous
GitHub form:

```elixir
{:obscura, github: "hfiguera/obscura", branch: "main"}
```

After the first Hex release, the normal application dependency should be:

```elixir
{:obscura, "~> 0.1.0"}
```

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

In the Profiles workbench:

1. Select `Emily GPU`.
2. Enable `Allow model downloads` only after accepting the external model
   terms and disk requirements.
3. Prepare `:balanced` or `:accurate` once.
4. Reuse the prepared runtime from the Text workbench for that LiveView
   session.

Without the Download option, preparation is cache-only. `:accurate` requires
two external model repositories and considerably more disk and memory than
`:balanced`. The model licenses remain the deployer's responsibility.

The example intentionally keeps prepared runtimes in the connected LiveView
session. A production application should prepare shared runtimes under its
supervision tree with `Obscura.Profile.Preparer` and reuse them across requests.

## Plug API

The JSON endpoint runs `Obscura.Phoenix.Plug` in assign mode and returns only
the redacted copy:

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
