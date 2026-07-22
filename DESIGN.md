---
name: Obscura Workbench
description: A restrained integration workbench for inspecting Obscura's public capabilities.
colors:
  ink: "#17211f"
  muted: "#66716e"
  line: "#d9dfdc"
  soft-line: "#e9eeeb"
  paper: "#ffffff"
  canvas: "#f4f7f5"
  sidebar: "#202826"
  sidebar-muted: "#aeb8b4"
  teal: "#087f70"
  teal-dark: "#06685c"
  teal-soft: "#e7f5f1"
  success: "#27815e"
  warning: "#a66205"
  error: "#b43838"
  brand-mark-ink: "#dff8ef"
  topbar-muted: "#9eaaa6"
  topbar-status: "#c7d0cd"
  status-idle: "#8a9591"
  status-ready: "#45c58f"
  navigation-border: "#445652"
  navigation-indicator: "#46c6ad"
  sidebar-foot: "#95a39e"
  field-label: "#44504d"
  control-line: "#cbd4d0"
  disabled-text: "#919a96"
  disabled-line: "#e0e5e2"
  empty-text: "#95a09c"
  error-ink: "#7d2323"
  error-surface: "#fff0f0"
  error-line: "#efc6c6"
  output-ink: "#26312e"
  entity-ink: "#075f54"
  entity-surface: "#dff3ee"
  icon-ink: "#46534f"
  icon-line: "#ccd5d1"
  interactive-line: "#79bcae"
  success-line: "#bddfcd"
  chunk-ink: "#5a4929"
  chunk-surface: "#fff5d9"
  chunk-line: "#ecd9a7"
  api-ink: "#45524e"
  stability-ink: "#3f5c51"
  runtime-ink: "#5d6864"
  success-ink: "#206046"
  success-surface: "#dff2e8"
  error-strong: "#852c2c"
  error-soft: "#fde7e7"
typography:
  scale:
    metadata: "10px"
    compact: "11px"
    label: "12px"
    body: "13px"
    title: "14px"
    metric: "22px"
    headline: "24px"
  headline:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0"
  title:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "14px"
    fontWeight: 700
    letterSpacing: "0"
  body:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.55
    letterSpacing: "0"
  label:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "12px"
    fontWeight: 700
    letterSpacing: "0"
  mono:
    fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.55
    letterSpacing: "0"
rounded:
  badge: "4px"
  control: "5px"
  navigation: "6px"
  panel: "7px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "22px"
  workspace: "28px"
components:
  button-primary:
    backgroundColor: "{colors.teal}"
    textColor: "{colors.paper}"
    rounded: "{rounded.control}"
    padding: "0 16px"
    height: "40px"
  button-primary-hover:
    backgroundColor: "{colors.teal-dark}"
    textColor: "{colors.paper}"
    rounded: "{rounded.control}"
  button-secondary:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "0 12px"
    height: "36px"
  input:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "0 10px"
    height: "38px"
  entity-selected:
    backgroundColor: "{colors.teal-soft}"
    textColor: "{colors.teal-dark}"
    rounded: "{rounded.badge}"
    padding: "8px 7px"
---

# Design System: Obscura Workbench

## Overview

**Creative North Star: "The Integration Lab"**

The Obscura Workbench is a quiet technical surface where behavior can be exercised and inspected without ceremony. It uses restrained neutral layers, a dark utility shell, and one controlled teal accent so input, state, output, and API boundaries remain the strongest signals on every screen.

Density is intentional but ordered. Familiar controls, compact labels, byte-safe output, and explicit runtime states make the interface feel like a dependable development instrument rather than a product tour. It must not drift into a marketing landing page, compliance dashboard, decorative card catalog, generic admin template, or playful illustrated tool.

**Key Characteristics:**

- Restrained light workspace inside a dark utility shell.
- Teal reserved for commands, current navigation, focus, and selected state.
- Compact system typography with monospace for APIs, inputs, and outputs.
- Flat, bordered structure with shallow elevation used only for large working surfaces and transient feedback.
- Responsive structure that collapses columns before reducing legibility.

## Colors

The palette combines near-black green neutrals with a measured teal signal and explicit semantic colors.

### Primary

- **Operational Teal** (`#087f70`): Primary commands, the brand mark, and high-confidence interactive emphasis.
- **Deep Teal** (`#06685c`): Hover states and selected text where the primary teal needs stronger contrast.
- **Selection Wash** (`#e7f5f1`): Selected entities and low-intensity teal state backgrounds.

### Neutral

- **Workbench Ink** (`#17211f`): Primary text and high-emphasis labels.
- **Instrument Gray** (`#66716e`): Supporting copy, metadata, and secondary state text.
- **Canvas Mist** (`#f4f7f5`): Page background behind operational surfaces.
- **Paper** (`#ffffff`): Inputs, panels, and active control surfaces.
- **Hairline** (`#d9dfdc`) and **Soft Hairline** (`#e9eeeb`): Structural boundaries and dense table dividers.
- **Utility Charcoal** (`#202826`): Navigation shell and tool separation.
- **Sidebar Gray** (`#aeb8b4`): Inactive navigation text on the dark shell.

### Semantic

- **Success Green** (`#27815e`): Ready and successful runtime states.
- **Warning Amber** (`#a66205`): Caution states that require attention without implying failure.
- **Error Red** (`#b43838`): Validation and runtime failures.

### Named Rules

**The Signal-Only Accent Rule.** Teal marks an action, current selection, focus, or meaningful state. It is never ambient decoration.

**The State Redundancy Rule.** Success, warning, error, loading, and disabled states use words or icons in addition to color.

## Typography

**Display Font:** Inter with the system sans-serif stack
**Body Font:** Inter with the system sans-serif stack
**Label/Mono Font:** `ui-monospace`, SFMono-Regular, Menlo, Monaco, Consolas

**Character:** One neutral sans-serif family keeps the product interface familiar and compact. Monospace creates a clear boundary around code, API names, payloads, model implementations, and transformed output.

### Hierarchy

- **Headline** (700, `24px`, `1.2`): Workbench section titles only.
- **Title** (700, `14px`): Pane titles, navigation labels, and compact grouped headings.
- **Body** (400, `13px`, `1.55`): Operational copy and result details; explanatory prose should remain within `75ch`.
- **Label** (700, `12px`, letter spacing `0`): Form labels, commands, and state controls.
- **Metadata** (400-800, `10-11px`, letter spacing `0`): Badges, table headers, counts, and terse supporting hints.
- **Monospace** (400, `11-13px`, `1.55`): API calls, implementation names, synthetic payloads, and output.

### Named Rules

**The Data Boundary Rule.** Use monospace when text represents code, a payload, a token, an identifier, or machine output; use sans-serif for decisions and guidance.

**The Fixed Scale Rule.** Product typography uses stable pixel sizes. Do not scale labels or headings with viewport width.

## Elevation

The system is flat by default. Tonal layers and one-pixel boundaries define most hierarchy. The two-pane operation surface may use the existing low ambient shadow (`0 10px 30px rgba(33, 48, 43, 0.05)`) to separate the primary work area from the canvas. Transient flash messages use the stronger existing shadow (`0 12px 32px rgba(23, 33, 31, 0.18)`) because they must remain legible above active work.

### Shadow Vocabulary

- **Workspace Ambient** (`0 10px 30px rgba(33, 48, 43, 0.05)`): The main operation surface only.
- **Transient Overlay** (`0 12px 32px rgba(23, 33, 31, 0.18)`): Flash and connection feedback only.
- **Selected Control** (`0 1px 3px rgba(23, 33, 31, 0.12)`): Active segment within a segmented control.

### Named Rules

**The Flat-by-Default Rule.** Tables, fields, bands, badges, and ordinary panels use boundaries or tonal contrast, not decorative shadows.

## Components

Components are compact, familiar, and complete across default, hover, focus, selected, disabled, loading, success, and error states.

### Buttons

- **Shape:** Compact rectangular controls with `5px` corners.
- **Primary:** Operational Teal with white text, `40px` height, and `16px` horizontal padding.
- **Hover / Focus:** Deep Teal on hover; a visible three-pixel translucent teal focus outline with one-pixel offset.
- **Secondary:** White surface, Workbench Ink text, one-pixel Hairline border, and `36px` minimum height.
- **Loading / Disabled:** Preserve dimensions, remove repeat interaction, and pair reduced opacity with a textual state.

### Chips

- **Style:** Entity choices and status badges use `4px` corners and compact `10px` labels.
- **State:** Selected entities use Selection Wash, Deep Teal text, and a stronger teal boundary. Unsupported entities retain their label while visibly disabling interaction.

### Cards / Containers

- **Corner Style:** `6-7px`; never pill-shaped or heavily rounded.
- **Background:** Paper for working surfaces, Canvas Mist or near-white tonal layers for secondary panes.
- **Shadow Strategy:** Flat by default; only the main operation surface receives Workspace Ambient elevation.
- **Border:** One-pixel Hairline or Soft Hairline boundaries.
- **Internal Padding:** `16-22px` for ordinary working areas; `28px` for the desktop workspace boundary.

### Inputs / Fields

- **Style:** White background, Workbench Ink text, one-pixel neutral stroke, `5px` corners, and stable `38px` control height.
- **Focus:** Three-pixel translucent teal outline with one-pixel offset.
- **Error / Disabled:** Error copy uses a red-tinted surface and explicit text. Disabled controls retain readable labels, use a neutral fill, and show a not-allowed cursor.

### Navigation

- **Style:** A dark top bar and dark tool sidebar separate global identity from the active workbench. Inactive items use Sidebar Gray; hover uses a lighter charcoal surface; active items use white text, a defined border, and a narrow teal inset indicator.
- **Responsive behavior:** Below `760px`, the sidebar becomes a horizontally scrollable tool strip beneath the top bar. Labels and icon dimensions remain fixed.

### Operation Surface

Input and result panes share one bounded surface so the cause-and-effect relationship stays visible. At widths below `1060px`, the panes stack vertically with a divider; no nested cards are introduced.

## Do's and Don'ts

### Do:

- **Do** keep the selected capability, API name, input, result, and relevant operational state visible together.
- **Do** reserve `#087f70` for primary actions, current navigation, focus, and selected state.
- **Do** use one-pixel boundaries and restrained tonal layers for dense structure.
- **Do** use synthetic examples and explicit labels for model downloads, cache-only preparation, unsupported entities, and reversible operations.
- **Do** keep every control keyboard operable with a visible focus treatment and a non-color state cue.
- **Do** collapse pane structure at `1060px` and navigation structure at `760px` before content becomes cramped.

### Don't:

- **Don't** turn the workbench into a marketing landing page with oversized claims, hero copy, or conversion-oriented sections.
- **Don't** present a compliance dashboard or imply certification, guaranteed PII removal, or universal model accuracy.
- **Don't** use a decorative card catalog that fragments one workflow into floating containers.
- **Don't** make the tool playful, illustrated, glassy, neon, or heavily animated.
- **Don't** apply generic admin-template components when they obscure Obscura's actual API concepts.
- **Don't** introduce gradient text, decorative grid backgrounds, broad purple or blue gradients, oversized corner radii, or border-plus-wide-shadow ghost cards.
- **Don't** use animation that does not communicate a state change, and always provide a reduced-motion alternative when motion is introduced.
