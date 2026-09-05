---
name: Civic Horizon
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#44474d'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#75777e'
  outline-variant: '#c5c6ce'
  surface-tint: '#4e5f7d'
  primary: '#031631'
  on-primary: '#ffffff'
  primary-container: '#1a2b47'
  on-primary-container: '#8293b4'
  inverse-primary: '#b6c7ea'
  secondary: '#0051d5'
  on-secondary: '#ffffff'
  secondary-container: '#316bf3'
  on-secondary-container: '#fefcff'
  tertiary: '#131718'
  on-tertiary: '#ffffff'
  tertiary-container: '#282b2d'
  on-tertiary-container: '#8f9294'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d6e3ff'
  primary-fixed-dim: '#b6c7ea'
  on-primary-fixed: '#081b37'
  on-primary-fixed-variant: '#374765'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#b4c5ff'
  on-secondary-fixed: '#00174b'
  on-secondary-fixed-variant: '#003ea8'
  tertiary-fixed: '#e0e3e5'
  tertiary-fixed-dim: '#c4c7c9'
  on-tertiary-fixed: '#191c1e'
  on-tertiary-fixed-variant: '#444749'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-max: 1200px
  gutter: 24px
  margin-mobile: 16px
---

## Brand & Style

The design system is centered on the principles of **Civic Transparency** and **Radical Accessibility**. The target audience encompasses the entire demographic spectrum of a city's population—from tech-savvy youth to elderly residents. The UI must evoke a sense of reliability, efficiency, and public service.

The design style is **Corporate Modern with a Humanist touch**. It avoids the coldness of traditional government portals by utilizing generous whitespace, soft edges, and a clear information hierarchy. The interface prioritizes clarity over ornamentation, ensuring that the primary action—reporting and tracking infrastructure—is never more than two taps away. The aesthetic is clean, professional, and stable, reinforcing the trust citizens place in their public institutions.

## Colors

The palette is anchored by **Deep Navy (#1A2B47)** for core branding and high-level navigation, providing a foundation of authority and trust. **Action Blue (#2563EB)** is used for interactive elements, primary buttons, and links to signify momentum and progress.

The background uses a pristine white, while **Surface Gray (#F8FAFC)** provides subtle contrast for card backgrounds and input fields. Semantic colors are strictly applied to infrastructure status:
- **Urgent (Red):** Immediate hazards or blocked services.
- **In-Progress (Yellow):** Active maintenance or review.
- **Resolved (Green):** Completed tasks and success states.
- **Neutral (Slate):** Drafts or archived information.

## Typography

This design system utilizes **Inter** for its exceptional legibility and neutral, systematic tone. It provides a highly functional "utility" feel that works perfectly for data-heavy civic reporting.

- **Headlines:** Use Bold and Semi-Bold weights with tight letter-spacing for a modern, authoritative look.
- **Body Text:** Use Regular weight with generous line-height (1.5x) to ensure readability for users with varying visual abilities.
- **Labels:** Use Medium weight and slight letter-spacing for UI micro-copy and metadata to distinguish them from editorial content.
- **Mobile Scaling:** Large headlines automatically scale down on mobile viewports to prevent awkward line breaks while maintaining a clear typographic scale.

## Layout & Spacing

The layout follows a **8px soft-grid system** to ensure consistency across all components.

- **Grid Model:** A 12-column fluid grid is used for desktop (max-width: 1200px) with 24px gutters. For mobile, the grid collapses to a single column with 16px side margins.
- **Spacing Logic:** Vertical spacing between sections should use `xl` (32px), while spacing between related elements within a card uses `sm` (8px) or `md` (16px).
- **Safe Areas:** Interactive elements like buttons must maintain a minimum 44px hit area to ensure accessibility on touch devices.

## Elevation & Depth

This design system uses a **Tonal Layering** approach combined with soft, ambient shadows.

- **Level 0 (Base):** Pure White (#FFFFFF).
- **Level 1 (Cards):** Surface Gray (#F8FAFC) with a 1px border (#E2E8F0).
- **Level 2 (Interaction):** When a user hovers or interacts with a card, apply a soft ambient shadow (0px 4px 20px rgba(26, 43, 71, 0.08)).
- **Overlays:** Modals and dropdowns use a more pronounced shadow (0px 10px 30px rgba(26, 43, 71, 0.12)) to clearly separate them from the background.
- **Contrast:** No heavy black shadows are permitted; all shadows are tinted with the Deep Navy primary color to maintain brand harmony.

## Shapes

The shape language is defined by **Soft Geometricism**. All primary containers, buttons, and input fields use a consistent 12px (`0.5rem`) radius to feel approachable and friendly.

- **Components:** Buttons and input fields use the base 12px radius.
- **Large Containers:** Content cards and feature blocks use `rounded-lg` (16px).
- **Status Tags:** Use a fully rounded pill-shape (999px) to distinguish them from functional buttons.

## Components

### Buttons
- **Primary:** Action Blue background, White text. High-contrast and easily identifiable.
- **Secondary:** White background, Deep Navy border (1px), Deep Navy text.
- **Ghost:** No background or border, used for less frequent actions like "Cancel".

### Input Fields
- Structured with a clear label above the field.
- Background: White.
- Border: 1.5px Slate (#CBD5E1). On focus, border changes to Action Blue.
- Error state: 1.5px Red border with a small helper icon.

### Status Chips
- Pill-shaped with a low-opacity background of the status color (e.g., 10% opacity) and 100% opacity text for maximum readability.

### Report Cards
- The central component of the platform.
- 12px rounded corners, 1px subtle border, and a 5px vertical accent bar on the left edge that matches the current status color (Red/Yellow/Green).

### Navigation
- A simple, sticky top-bar featuring the city logo, a search bar for reports, and a "Profile/My Reports" toggle.