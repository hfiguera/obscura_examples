# Product

## Register

product

## Platform

web

## Users

The primary users are Elixir developers evaluating Obscura or learning how to integrate its stable public APIs. They use the workbench locally with synthetic data to inspect detection, anonymization, structured traversal, vault-backed pseudonymization, LLM rehydration, logger safety, Plug integration, and model-profile preparation.

Obscura maintainers are a secondary audience. For them, the app is an external-consumer contract test that must reveal stale documentation, unsupported options, model setup failures, and accidental reliance on repository internals before a release.

## Product Purpose

Obscura Examples is executable documentation for Obscura. It turns the library's stable capabilities into focused, inspectable workflows and demonstrates the operational setup that real applications must perform. Success means a developer can run a synthetic example, understand the public API involved, distinguish dependency-light and model-backed behavior, and leave with an integration pattern they can reproduce in their own application.

The app demonstrates behavior; it does not claim universal detection, regulatory compliance, production memory zeroization, or ownership of third-party model licenses.

## Positioning

The shortest trustworthy path from Obscura's public API documentation to a working external Elixir integration.

## Brand Personality

Precise, trustworthy, pragmatic. The interface should feel like a calm integration workbench: technically serious, candid about limitations, and efficient for repeated inspection. Confidence comes from visible inputs, outputs, states, and API boundaries rather than promotional claims.

## Anti-references

- A marketing landing page with oversized claims, hero copy, or conversion-oriented sections.
- A compliance dashboard that implies certification or guaranteed PII removal.
- A decorative card catalog that fragments one workflow into many floating containers.
- A playful, illustrated, glassy, neon, or heavily animated developer tool.
- A generic admin template whose controls obscure the actual Obscura concepts being demonstrated.

## Design Principles

1. **Make the public contract inspectable.** Keep the selected capability, relevant options, API name, input, result, and operational state visible together.
2. **Use safe defaults and honest boundaries.** Start with synthetic data and the dependency-light profile; make downloads, model preparation, unsupported entities, and residual risks explicit.
3. **Keep workflows direct.** Prefer familiar controls, compact hierarchy, and immediate feedback over explanatory marketing copy or decorative composition.
4. **Demonstrate realistic integration.** Exercise only public Obscura APIs and show reusable runtime, vault, structured-data, logger, and Plug patterns as an external application would use them.
5. **Preserve user control.** Never infer model downloads, hide destructive transformations, or blur the difference between detection, anonymization, and reversible pseudonymization.

## Accessibility & Inclusion

Target WCAG 2.2 AA for the web interface. All workflows must remain keyboard operable with visible focus, semantic labels, non-color state indicators, readable contrast, and coherent responsive layouts. Respect reduced-motion preferences, avoid decorative motion, and keep errors and preparation progress available to assistive technology without exposing raw sensitive values unnecessarily.
