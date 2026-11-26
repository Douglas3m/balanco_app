---
name: Balanço Patrimonial System
colors:
  surface: '#f9f9ff'
  surface-dim: '#cfdaf2'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee8ff'
  surface-container-highest: '#d8e3fb'
  on-surface: '#111c2d'
  on-surface-variant: '#444651'
  inverse-surface: '#263143'
  inverse-on-surface: '#ecf1ff'
  outline: '#757682'
  outline-variant: '#c5c5d3'
  surface-tint: '#4059aa'
  primary: '#00236f'
  on-primary: '#ffffff'
  primary-container: '#1e3a8a'
  on-primary-container: '#90a8ff'
  inverse-primary: '#b6c4ff'
  secondary: '#0058be'
  on-secondary: '#ffffff'
  secondary-container: '#2170e4'
  on-secondary-container: '#fefcff'
  tertiary: '#00311f'
  on-tertiary: '#ffffff'
  tertiary-container: '#004a31'
  on-tertiary-container: '#27c38a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b6c4ff'
  on-primary-fixed: '#00164e'
  on-primary-fixed-variant: '#264191'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#adc6ff'
  on-secondary-fixed: '#001a42'
  on-secondary-fixed-variant: '#004395'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f9f9ff'
  on-background: '#111c2d'
  surface-variant: '#d8e3fb'
typography:
  headline-xl:
    fontFamily: Outfit
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Outfit
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Outfit
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Outfit
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Outfit
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 1rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an institutional, robust, and highly functional visual language tailored for asset management, field inventory, cataloging, and patrimonial auditing across web and mobile platforms.

### Personality & Audience
- **Attributes:** Dependable, exact, modern, structured, and resilient.
- **Target Audience:** Asset managers, field inventory operators, fiscal auditors, warehouse coordinators, and administrative executives.
- **Emotional Response:** Inspires absolute confidence in data fidelity, operational poise in fast-paced field operations (offline auditing, barcode/RFID scanning), and cognitive calm when examining dense data tables or executive fiscal reports.

### Aesthetic Direction: Modern Corporate Precision
The design system combines **Corporate Modernism** with clean **Card-Based Architecture**. It features deep navy blues reflecting authority and balance (directly honoring the stylized scale mark in the brand identity), crisp white container surfaces over an airy `#F8FAFC` foundation, subtle hairline borders, and purposeful emerald accents for verification and status affirmation.

## Colors

The palette balances deep naval institutional stability with vibrant functional indicators, ensuring high-contrast clarity whether viewed on ruggedized mobile screens outdoors or high-resolution desktop control panels.

### Palette Architecture
- **Primary (`#1E3A8A`):** Deep Navy. Applied to key navigation bars, critical CTA buttons, brand anchors, and prominent active navigation items.
- **Secondary (`#3B82F6`):** Vibrant Slate Blue. Handles interactive focal points, focus rings, selected table rows, active tab indicators, and progress tracks.
- **Tertiary / Success (`#10B981`):** Emerald Green. Reserved for audited items, reconciled inventory checks, positive balance deltas, and success validation badges.
- **Neutral Primary (`#1E293B`):** Deep Slate. Main typographic color for headings, vital metric figures, and high-emphasis data.
- **Neutral Secondary (`#334155` / `#64748B`):** Slate. Secondary labels, metadata timestamps, table subtitles, and muted iconography.
- **Surface Canvas (`#F8FAFC`):** Soft luminous slate background reducing eye fatigue during prolonged auditing sessions.
- **Surface Pure (`#FFFFFF`):** High-clarity white card backgrounds providing clean separation for asset lists and data modules.
- **Border / Divider (`#E2E8F0`):** Subtle border delineating cards, table headers, and form inputs without visual friction.

## Typography

The typographic hierarchy relies on a functional pair: **Outfit** for structural headers and numerical summary highlights, providing a clean geometric punch aligned with the company logo; and **Inter** for tables, asset manifests, form inputs, and operational body copy.

### Usage Directives
- **Outfit:** Headings, KPI metric numbers, dialog titles, and card headers. Keeps numbers open and easily scanned at a distance.
- **Inter:** Tabular figures, serial numbers, RFID tags, barcode displays, form labels, and detailed descriptions. Use `tnum` (tabular numbers) CSS settings for inventory quantities and monetary values to ensure vertical column alignment.

## Layout & Spacing

The layout operates on a standard 8px baseline grid designed to scale seamlessly from warehouse tablets to multi-monitor office setups.

### Grid Systems
- **Desktop (>= 1024px):** 12-column fluid layout with `margin: 2rem` and `gutter: 1.5rem`. Accommodates side navigation, dense tabular asset views, and filter panels.
- **Tablet (768px - 1023px):** 8-column layout with collapsible sidebar into an off-canvas drawer; gutters fixed at `1.25rem`.
- **Mobile (< 768px):** 4-column fluid layout with single-column card stacking, `margin: 1rem`, and sticky bottom action bars for single-handed field inventory logging.

### Component Spacing Rhythm
- **Internal Card Padding:** `space-md` (16px) on mobile; `space-lg` (24px) on desktop dashboards.
- **Form Group Spacing:** Vertical gap of `space-md` (16px) between fields; `space-xs` (4px) between input label and control.

## Elevation & Depth

This system avoids heavy, muddy drop shadows in favor of ambient multi-stop elevation and crisp hairline containment, ensuring pristine visibility under high ambient lighting.

### Elevation Levels
- **Level 0 (Flat / Canvas):** Applied to the main page canvas (`#F8FAFC`).
- **Level 1 (Card Default):** `0px 1px 3px 0px rgba(15, 23, 42, 0.05), 0px 1px 2px -1px rgba(15, 23, 42, 0.05)`, backed by a border stroke of `1px solid #E2E8F0`. Used for data cards, asset rows, and statistic tiles.
- **Level 2 (Hover / Active Cards):** `0px 4px 6px -1px rgba(15, 23, 42, 0.07), 0px 2px 4px -2px rgba(15, 23, 42, 0.05)`. Applied when hovering over catalog items or interactive cards.
- **Level 3 (Dropdowns & Popovers):** `0px 10px 15px -3px rgba(15, 23, 42, 0.08), 0px 4px 6px -4px rgba(15, 23, 42, 0.04)`.
- **Level 4 (Modals & Bottom Drawers):** `0px 20px 25px -5px rgba(15, 23, 42, 0.1), 0px 8px 10px -6px rgba(15, 23, 42, 0.04)`. Accompanied by a 40% opacity navy backdrop veil (`rgba(15, 23, 42, 0.4)`).

## Shapes

The shape system employs roundedness level **2**, which standardizes interactive elements and surfaces between **12px (`0.75rem`)** and **16px (`1rem`)**, creating a contemporary yet sturdy look.

### Shape Scale
- **Small Controls (Buttons, Inputs, Badges):** `rounded-md` (8px / `0.5rem`) for compact structural integrity.
- **Medium Elements (Cards, Panels, Modals):** `rounded-lg` (12px / `0.75rem`) to `rounded-xl` (16px / `1rem`), matching the required 12px–16px card curvature.
- **Field Action Pills & Quick Filters:** Fully rounded pill radius (`9999px`) used strictly for dynamic filter pills and status chips.

## Components

### Buttons
- **Primary:** Solid `#1E3A8A` background, white label, 8px radius, height of 40px (desktop) or 48px (touch/field target). Hover shifts to `#172554`.
- **Secondary:** Transparent with 1px `#CBD5E1` border, `#1E293B` label. Hover brings background `#F1F5F9`.
- **Success Action:** Solid `#10B981` background, white text. Specifically for "Auditar Item", "Aprovar Balanço", or "Salvar Tombamento".

### Input Fields & Search Bars
- **Style:** Pure white surface, 1px border in `#CBD5E1`, 8px radius, height of 42px (desktop) or 48px (mobile).
- **Focus State:** 2px ring in secondary `#3B82F6` with subtle 20% alpha glow; label color transitions to `#1E3A8A`.
- **Field Inventory Search:** Enhanced search box with integrated barcode/QR scanner quick-tap button on mobile devices.

### Cards & Asset Tiles
- **Structure:** White (`#FFFFFF`) background, 12px–16px border-radius, hairline stroke `#E2E8F0`, elevation Level 1.
- **Composition:** Prominent asset serial / tombamento code in `Outfit 600`, asset class badge top right, contextual specifications in `Inter 400`, and bottom status bar (e.g., "Localização: Setor B - Bloco 2").

### Badges & Status Chips
- **Reconciled / Audited:** Soft emerald tint (`#ECFDF5`) background, `#047857` text, solid 6px emerald status dot.
- **Pending / In Progress:** Soft amber tint (`#FFFBEB`) background, `#B45309` text.
- **Discrepancy / Damaged:** Soft crimson tint (`#FEF2F2`) background, `#B91C1C` text.

### Tables & Data Lists
- **Headers:** Background `#F8FAFC`, uppercase `label-sm` in `#64748B`, bottom divider `1px solid #E2E8F0`.
- **Rows:** Alternating soft hover state `#F8FAFC`, height 52px for standard rows, padded with `space-md`. Support batch selection checkboxes with `#1E3A8A` check fill.