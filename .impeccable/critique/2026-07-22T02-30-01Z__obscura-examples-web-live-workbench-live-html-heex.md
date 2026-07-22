---
target: the Obscura workbench
total_score: 37
p0_count: 0
p1_count: 0
timestamp: 2026-07-22T02-30-01Z
slug: obscura-examples-web-live-workbench-live-html-heex
---
Method: dual-agent post-change assessment (A: 019f878c-f4cb-74e3-9554-fa2f7f7d073e; B: 019f878c-f533-7590-b0f3-390acc602956), parent browser validation, and local deterministic scan.

## Design Health Score

| # | Heuristic | Score | Evidence |
|---|---|---:|---|
| 1 | Visibility of System Status | 4 | Mode-specific summaries, explicit preparation/preflight states, and completion notices are visible and announced without exposing raw output. |
| 2 | Match System / Real World | 4 | Provider output is explicitly simulated, risk language is qualified, and model/cache/backend terms are concrete. |
| 3 | User Control and Freedom | 4 | Entity presets, preparation cancellation, and confirmed vault clearing all preserve a clear recovery path. |
| 4 | Consistency and Standards | 4 | Active capability state, result contracts, controls, and responsive layouts use consistent semantics. |
| 5 | Error Prevention | 4 | Downloads remain opt-in, cache-only is explicit, unsupported entities cannot be selected, and destructive clearing is confirmed. |
| 6 | Recognition Rather Than Recall | 4 | Common/All/None presets, advanced disclosure, preflight remediation, and model provenance keep decisions visible. |
| 7 | Flexibility and Efficiency | 3 | Common workflows are direct and copyable; model setup remains inherently multi-step. |
| 8 | Aesthetic and Minimalist Design | 3 | The restrained integration-lab language remains coherent; Profiles is necessarily information-dense. |
| 9 | Error Recovery | 4 | JSON locations, preparation cancellation, late-progress suppression, and vault completion are actionable. |
| 10 | Help and Documentation | 3 | Inline and README guidance cover operational boundaries; real model preparation remains opt-in and resource-dependent. |
| **Total** | | **37/40** | **Up from 26/40; no P0 or P1 findings remain.** |

## Anti-Patterns Verdict

The workbench retains a specific executable-documentation character and does not read as generic AI-generated UI. The local Impeccable detector returned `[]` for the LiveView template and CSS after the final fixes.

## Resolved Priority Findings

- Public-contract language now distinguishes local simulation, configured coverage, residual risk, and intentional PII restoration.
- Detection and anonymization use different headings, counts, columns, and post-submit summaries.
- Mobile Profiles uses three stacked labeled records; desktop retains the comparison table. No page-level overflow was observed at 390x844 or 1440x900.
- Custom radios and checkboxes expose visible 3 px focus treatment, and selected/unavailable chips add non-color cues.
- Common, All, None, and Advanced controls respect profile capabilities and preserve only supported selections.
- Preparation shows model sources, approximate cache footprints, cache location, backend/device guidance, upstream licensing responsibility, public preflight remediation, retained backend/download state, duplicate prevention, and cancellation.
- Raw PII and transformed outputs are outside live regions; only bounded summaries and diagnostics are announced.
- Capability switches expose `aria-pressed`, restore the new heading at mobile scroll positions, and move focus to that heading.
- Vault clearing moves focus into confirmation, back on cancellation, and to the completion notice after clearing.
- The local Plug endpoint has precise wording and an accessible copy action.

## Responsive And Accessibility Evidence

- Desktop 1440x900: document width 1440 px; Profiles table and actions remained within its 1160 px section.
- Mobile 390x844: document width 390 px; mobile profile cards replaced the table and both Prepare actions measured from x=29 to x=361.
- Switching from Profiles at scrollY 1205 to Structured left the new H1 at top 153.5 px, focused, with scrollY 5.
- Keyboard-focused radio and checkbox surfaces each reported `:focus-visible` with a solid 3 px outline.
- Vault focus moved to `cancel-clear-vault`, returned to `request-clear-vault`, and completed at `vault-clear-notice`.
- Every synthetic workbench completed without page-level horizontal overflow.

## Validation

- `mix format --check-formatted`: passed.
- `mix compile --warnings-as-errors`: passed.
- `mix test`: 30 passed.
- `mix assets.deploy`: passed.
- Impeccable detector: zero findings after final fixes.
- No model downloads or real model preparation occurred during ordinary tests.

## Remaining Risks

- Real multi-gigabyte model preparation and cancellation were not exercised in the ordinary UI suite; unit-level LiveView state tests and earlier Obscura preparation evidence cover the contract without downloading assets here.
- Model asset sizes are measured cache approximations, and TNER checkpoint licensing remains unresolved as disclosed in the UI.
- The in-app browser reported an unattributed `MutationObserver.observe` error also seen before these changes; no project source contains a `MutationObserver`, so it remains browser/development instrumentation rather than an attributed app defect.

Questions skipped because this goal supplied an accepted entity-selection direction and required all actionable findings to be resolved rather than presenting further design choices.
