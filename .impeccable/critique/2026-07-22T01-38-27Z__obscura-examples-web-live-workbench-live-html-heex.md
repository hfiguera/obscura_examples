---
target: the Obscura workbench
total_score: 26
p0_count: 0
p1_count: 3
timestamp: 2026-07-22T01-38-27Z
slug: obscura-examples-web-live-workbench-live-html-heex
---
Method: dual-agent (A: 019f876f-1bab-7bd2-a2f0-eb6eacd30c5f · B: 019f876f-1c0d-7bc0-a6df-1882f6778694)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|------:|-----------|
| 1 | Visibility of System Status | 3 | Active navigation, result counts, errors, and runtime states are visible; generic Ready states and color-led vault readiness remain ambiguous. |
| 2 | Match System / Real World | 3 | Elixir APIs fit the audience, but Emily GPU, Binary, and Provider response need context. |
| 3 | User Control and Freedom | 2 | Navigation is direct, but there is no reset or confirmation for irreversible vault clearing. |
| 4 | Consistency and Standards | 3 | Interaction patterns are consistent; matches and Value change meaning between detection and transformation modes. |
| 5 | Error Prevention | 3 | Synthetic defaults, capability filtering, and explicit download permission are strong; JSON errors arrive only after submission. |
| 6 | Recognition Rather Than Recall | 3 | Labels and API names remain visible; mobile Profiles separates identity from offscreen controls. |
| 7 | Flexibility and Efficiency | 2 | Direct workflows help, but entity presets, copy actions, and keyboard accelerators are absent. |
| 8 | Aesthetic and Minimalist Design | 3 | Calm and focused overall; fourteen entity choices and the profile metric strip add noise. |
| 9 | Error Recovery | 2 | Invalid JSON preserves input but lacks line, column, or a concrete correction. |
| 10 | Help and Documentation | 2 | API signatures help; backend choice, model provenance, asset cost, and operational boundaries need inline support. |
| **Total** | | **26/40** | **Solid foundation with material contract, accessibility, and mobile gaps.** |

## Anti-Patterns Verdict

**LLM assessment:** Low AI-slop risk. The restrained palette, compact type, conventional controls, consistent work surfaces, and lack of decorative effects feel intentional. Repeated uppercase kickers and the three-metric strip are mildly template-like but do not dominate the product.

**Deterministic scan:** `detect.mjs --json lib/obscura_examples_web/live/workbench_live.html.heex` returned `[]`, exit `0`: zero rules, findings, or locations. There are no detector false positives to discard.

**Visual overlays:** No overlay exists. The browser exposed a read-only evaluate surface: assigning `document.title` failed because it has only a getter, and `document.createElement` was unavailable. Browser DOM, screenshots, interactions, and console logs were used as fallback evidence. The only console error was an unattributed `MutationObserver.observe` type error, not an Impeccable finding.

## Overall Impression

The workbench already looks and behaves like serious executable documentation. Its largest opportunity is not visual restyling; it is making every label and operational choice as precise as the underlying Obscura contract, especially on mobile and around model assets.

## What's Working

- Inputs, API names, operational states, and outputs are co-located, reinforcing the external-consumer documentation goal.
- The visual system is disciplined: compact typography, meaningful monospace, restrained teal, shallow elevation, and familiar controls.
- Synthetic defaults, capability-aware entities, disabled unprepared profiles, explicit download permission, and preserved invalid input provide real safeguards.

## Cognitive Load

Moderate overall and high in mobile Profiles. The checklist fails chunking, minimal choices, progressive disclosure, and mobile working-memory support. Decision points above four visible options are the five-item capability navigation and the fourteen-item entity selector, which begins with eight selected choices.

## Emotional Journey

Arrival is calm and credible, and a successful Text or Structured run is the peak because results appear with counts and boundaries. Valleys occur when mobile results sit far below Run, profile preparation lacks asset and licensing context, safety language sounds absolute, reversible PII returns without renewed warning, and vault clearing has no confirmation or completion message.

## Priority Issues

### P1: Public-contract semantics are blurred

**Why it matters:** Provider response is locally fabricated, while Safe provider message, Log-safe output, matches, and Value can overstate safety or change meaning. This weakens the app's central promise of trustworthy executable documentation.

**Fix:** Label the output `Simulated provider response - no network call`; qualify safety as limited to configured entities; use action-specific result counts, headings, and table columns.

**Suggested command:** `$impeccable clarify the workbench result and safety language`

### P1: Mobile Profiles hides the primary action

**Why it matters:** At 390x844, the 712 px table sits in a 364 px viewport. Runtime state and Prepare controls are offscreen, while tall rows appear mostly blank before horizontal scrolling.

**Fix:** Replace the mobile table with stacked, labeled profile rows that keep identity, dependencies, assets, runtime state, and preparation controls together.

**Suggested command:** `$impeccable adapt the Profiles workbench for mobile`

### P1: Custom controls lack reliable visible keyboard focus

**Why it matters:** Segmented radios and entity checkboxes focus opacity-zero inputs without styling their visible surfaces, so keyboard users can lose their location.

**Fix:** Add `input:focus-visible + span` or `label:has(input:focus-visible)` treatment and test the full keyboard sequence with supported and disabled entities.

**Suggested command:** `$impeccable audit the workbench keyboard and focus behavior`

### P2: Text processing exposes too much complexity at once

**Why it matters:** Fourteen equal-weight entity choices dominate the workflow, and mobile users receive weak post-submit confirmation before scrolling to results.

**Fix:** Group entities, provide Common/All/None presets, progressively disclose less common entities, and move focus or a result summary to the command area after completion.

**Suggested command:** `$impeccable distill the Text entity selection workflow`

### P2: Model preparation lacks informed-consent detail

**Why it matters:** Allow model downloads states permission but not estimated size, model source, cache destination, licensing responsibility, device suitability, or the meaning of cache-only failure.

**Fix:** Add compact per-profile preparation facts and direct links before users grant download permission; keep Prepare disabled during work and preserve explicit cache-only behavior.

**Suggested command:** `$impeccable harden the model preparation workflow`

## Persona Red Flags

- **Jordan, first-time integrator:** Pseudonymize produces Provider response without disclosing simulation. Emily GPU versus Binary provides no decision support.
- **Sam, keyboard and assistive-technology user:** Action radios and entity chips do not show focus on their visible surfaces; vault readiness relies heavily on a green dot.
- **Casey, mobile user:** Text results require a long post-submit scroll, while Profile preparation requires undiscoverable horizontal scrolling.

## Minor Observations

- Empty-state Ready text measures approximately 2.62:1 contrast; small table headers are approximately 4.48:1, narrowly below AA.
- The curl example needs a copy action and a clearer statement that it exercises the Plug endpoint.
- The Profiles metric strip is visually prominent but contributes little to the next user decision.
- Invalid JSON errors should include line and column information with a correction example.
- Clearing a populated vault should require confirmation and report completion.

## Questions to Consider

- Is the Vault view demonstrating an LLM integration, or Obscura's safety boundary around one? The simulated response should make that distinction explicit.
- Can any output be called safe without naming configured entity coverage and residual-risk limits?
- If mobile profile actions are offscreen, should Profiles remain a table at that breakpoint?
- What do fourteen simultaneous entity choices teach better than a Common preset with advanced disclosure?
