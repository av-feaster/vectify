---
name: Desktop Professional
colors:
  surface: '#faf9fe'
  surface-dim: '#dad9df'
  surface-bright: '#faf9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f8'
  surface-container: '#eeedf3'
  surface-container-high: '#e9e7ed'
  surface-container-highest: '#e3e2e7'
  on-surface: '#1a1b1f'
  on-surface-variant: '#414755'
  inverse-surface: '#2f3034'
  inverse-on-surface: '#f1f0f5'
  outline: '#717786'
  outline-variant: '#c1c6d7'
  surface-tint: '#005bc1'
  primary: '#0058bc'
  on-primary: '#ffffff'
  primary-container: '#0070eb'
  on-primary-container: '#fefcff'
  inverse-primary: '#adc6ff'
  secondary: '#4c4aca'
  on-secondary: '#ffffff'
  secondary-container: '#6664e4'
  on-secondary-container: '#fffbff'
  tertiary: '#9e3d00'
  on-tertiary: '#ffffff'
  tertiary-container: '#c64f00'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a41'
  on-primary-fixed-variant: '#004493'
  secondary-fixed: '#e2dfff'
  secondary-fixed-dim: '#c2c1ff'
  on-secondary-fixed: '#0c006a'
  on-secondary-fixed-variant: '#3631b4'
  tertiary-fixed: '#ffdbcc'
  tertiary-fixed-dim: '#ffb595'
  on-tertiary-fixed: '#351000'
  on-tertiary-fixed-variant: '#7c2e00'
  background: '#faf9fe'
  on-background: '#1a1b1f'
  surface-variant: '#e3e2e7'
typography:
  h1:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  h2:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: '0'
  body-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  mono:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: '0'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  sidebar_width: 240px
  gutter: 16px
  margin: 24px
  container_padding: 20px
---

## Brand & Style

This design system is engineered for high-productivity macOS desktop environments. It leverages a **Corporate / Modern** aesthetic that prioritizes clarity, systematic organization, and native-feeling interactions. The brand personality is dependable and precise, designed to fade into the background so the user's data can take center stage. 

The visual language balances the warmth of rounded geometries with the cold precision of a technical utility. It evokes a sense of "expert tooling" through the use of subtle depth, rigorous alignment, and a restrained color palette that highlights actionable density over decorative flair.

## Colors

The palette is rooted in Apple’s diagnostic color language. The primary accent is a vibrant **System Blue**, providing a clear visual thread for primary actions and active states. 

- **Light Mode:** Uses a "Pure White" surface for content areas, contrasted against a "System Gray" sidebar and background to create structural separation.
- **Dark Mode:** Utilizes deep charcoal grays rather than pure black to maintain shadow definition and reduce eye strain.
- **Grays:** A scale of nine grays is used to define borders, secondary text, and inactive states, ensuring high legibility and a refined UI texture.
- **Status Indicators:** Saturated semantic colors are used sparingly for status pips and badges to ensure they immediately draw the eye within dense data tables.

## Typography

The system utilizes **Inter** as a highly legible alternative to SF Pro, maintaining the "Apple-style" clarity while ensuring cross-platform rendering consistency. 

- **Body Text:** Set at 13px, the macOS standard, to maximize information density without sacrificing readability.
- **Monospace:** **Space Grotesk** is used for logs and code snippets. It provides a technical, geometric edge that distinguishes data output from UI labels.
- **Hierarchy:** Weight is used more frequently than scale to differentiate information. Bold weights are reserved for headers and primary buttons, while Medium weights define navigation links.

## Layout & Spacing

This design system employs a **Fluid Grid** with fixed-width sidebar navigation. The layout is structured around a 4px baseline grid to ensure all elements align precisely.

- **Sidebar:** A 240px fixed-width column utilizing a background blur (vibrancy) effect.
- **Content Area:** A fluid container with 24px margins that scales with the window size.
- **Density:** Elements are grouped using tight 8px or 12px gaps, while major sections are separated by 24px or 32px to create clear visual "zones" of information.
- **Alignment:** Tables and logs should extend to the full width of their containers, utilizing internal padding of 12px for cell content.

## Elevation & Depth

Depth is communicated through **Tonal Layers** and **Glassmorphism**, mimicking the macOS desktop experience.

- **Level 0 (Base):** The main window background, using a subtle gray.
- **Level 1 (Surface):** The primary content cards and sidebar. These use a white (light mode) or dark gray (dark mode) fill with a 1px neutral border.
- **Level 2 (Overlay):** Dropdown menus, popovers, and modals. These feature a 12% opacity ambient shadow with a 16px blur and a 1px semi-transparent border to define the edge against similar background colors.
- **Vibrancy:** The sidebar must use a backdrop-filter blur (20px) to allow background colors to bleed through subtly, providing a sense of place.

## Shapes

The shape language is consistently **Rounded**, adhering to the modern macOS geometry.

- **Standard Elements:** Buttons, input fields, and chips use a 8px (rounded-md) corner radius.
- **Containers:** Large cards and the main sidebar selection highlights use a 10px or 12px (rounded-lg) radius.
- **Status Pips:** Small status indicators are perfectly circular (pill-shaped) to distinguish them from interactive buttons.
- **Borders:** All borders are kept to a hair-line 1px width using low-contrast grays (e.g., #E5E5E5 in light mode) to maintain a crisp look.

## Components

- **Sidebar Navigation:** Use transparent backgrounds for items, with a primary blue background and white text for the "Active" state. Include SF-style icons to the left of labels.
- **Buttons:**
    - *Primary:* Solid accent color with white text.
    - *Secondary:* Subtle gray ghost button with accent-colored text.
- **Structured Tables:** Clean headers with no vertical borders. Use 1px horizontal dividers. Text should be 13px Inter; status pips should appear in the first or last column.
- **Monospace Logs:** Contained in a "Level 1" surface with a slightly darker background than the main content area. Use a subtle border and 12px Space Grotesk.
- **Status Indicators:** 
    - *Success:* Green dot + "Success" label.
    - *Warning:* Amber dot + "Warning" label.
    - *Failure:* Red dot + "Failed" label.
- **Input Fields:** 1px border that turns into a 2px primary blue halo on focus. Labels are positioned above the field in 11px Medium weight.