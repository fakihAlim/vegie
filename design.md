---
name: Organic Vitality System
colors:
  surface: '#fbf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fbf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f3'
  surface-container: '#f0eded'
  surface-container-high: '#eae8e7'
  surface-container-highest: '#e4e2e1'
  on-surface: '#1b1c1c'
  on-surface-variant: '#42493e'
  inverse-surface: '#303030'
  inverse-on-surface: '#f2f0f0'
  outline: '#72796e'
  outline-variant: '#c2c9bb'
  surface-tint: '#3b6934'
  primary: '#154212'
  on-primary: '#ffffff'
  primary-container: '#2d5a27'
  on-primary-container: '#9dd090'
  inverse-primary: '#a1d494'
  secondary: '#406900'
  on-secondary: '#ffffff'
  secondary-container: '#baf474'
  on-secondary-container: '#447000'
  tertiary: '#343b31'
  on-tertiary: '#ffffff'
  tertiary-container: '#4b5247'
  on-tertiary-container: '#bec5b7'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#bcf0ae'
  primary-fixed-dim: '#a1d494'
  on-primary-fixed: '#002201'
  on-primary-fixed-variant: '#23501e'
  secondary-fixed: '#baf474'
  secondary-fixed-dim: '#9fd75b'
  on-secondary-fixed: '#102000'
  on-secondary-fixed-variant: '#2f4f00'
  tertiary-fixed: '#dee5d6'
  tertiary-fixed-dim: '#c2c9bb'
  on-tertiary-fixed: '#171d14'
  on-tertiary-fixed-variant: '#42493e'
  background: '#fbf9f8'
  on-background: '#1b1c1c'
  surface-variant: '#e4e2e1'
typography:
  headline-lg:
    fontFamily: Quicksand
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Quicksand
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Quicksand
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Quicksand
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Quicksand
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Quicksand
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  caption:
    fontFamily: Quicksand
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-padding-mobile: 20px
  container-padding-desktop: 40px
  gutter: 16px
  stack-sm: 12px
  stack-md: 24px
  stack-lg: 48px
---

## Brand & Style
The design system is anchored in the concept of "Organic Vitality." It aims to evoke a sense of freshness, health, and effortless intelligence. The target audience includes health-conscious individuals seeking a plant-based lifestyle, requiring a UI that feels both encouraging and technologically advanced. 

The aesthetic is a blend of **Minimalism** and **Modern Softness**. It prioritizes high whitespace and a low cognitive load to ensure that nutritional data and AI recommendations do not overwhelm the user. The interface should feel "breathable," using a "less is more" approach to information density, ensuring every element has room to resonate.

## Colors
The palette is rooted in the natural world. The primary color is a deep, trustworthy Forest Green (#2D5A27), used for core branding and primary actions. This is balanced by a vibrant Lime Green (#A8E063) for success states, progress indicators, and accents that signify growth. 

A very soft Mint-White (#F1F8E9) serves as the tertiary "surface" color to differentiate sections without the harshness of pure grey. The background remains a crisp, clean White to maintain a medical-grade cleanliness, while neutrals are kept to a soft Charcoal for text to reduce eye strain.

## Typography
This design system utilizes **Quicksand** exclusively to leverage its rounded terminals and friendly geometry. This choice humanizes the AI-driven data, making dietary advice feel like a conversation rather than a prescription. 

Headlines use a bolder weight with slight negative letter-spacing to create a strong visual anchor. Body text utilizes generous line-heights (1.5x) to maximize readability. For mobile devices, headlines scale down slightly to ensure that long plant names or meal titles do not wrap awkwardly.

## Layout & Spacing
The layout follows a **Fixed Grid** philosophy on desktop (max-width 1200px) and a fluid, single-column approach on mobile. To achieve the "low cognitive load" requirement, the system employs a spacious 8px-based rhythm.

- **Margins:** Mobile views use a minimum of 20px side margins to prevent content from feeling cramped.
- **Vertical Rhythm:** Elements are separated by "stacks"—generous vertical gaps (24px or 48px) that clearly delineate different pieces of information. 
- **Alignment:** All content is left-aligned to mimic natural reading patterns, with the exception of specific "Hero" or "Success" cards which may use center alignment for impact.

## Elevation & Depth
Depth is achieved through **Tonal Layers** and **Ambient Shadows** rather than stark borders. Surfaces are primarily differentiated by subtle shifts in background color (using the tertiary Mint-White).

When elevation is required (e.g., for floating action buttons or active cards), use a "Botanical Shadow": a very soft, diffused shadow with a slight green tint (#2D5A27 at 5-8% opacity) and a large blur radius (16px to 24px). This makes elements appear to lift gently off the page like a leaf, rather than sitting heavily on it. Avoid hard shadows or high-contrast inner glows.

## Shapes
Following the "ROUND_TWELVE" directive, the system adopts a **Rounded** profile. Base components like input fields and small buttons use a 0.5rem (8px) radius. Larger interactive elements, such as meal cards and diet summary containers, use `rounded-lg` (16px) or `rounded-xl` (24px). 

This consistent curvature eliminates "sharp" corners that can feel aggressive or clinical, reinforcing the friendly, approachable nature of the plant-based AI assistant.

## Components
- **Buttons:** Primary buttons are solid Forest Green with white text, featuring a subtle "bounce" hover state. Secondary buttons use a Forest Green outline with a Mint-White background.
- **Cards:** Cards are the primary container. They should be white, with a 1px border of Tertiary Green (#F1F8E9) or a soft ambient shadow. They include generous internal padding (24px).
- **Input Fields:** Soft Mint-White background with no border in their default state. Upon focus, they transition to a Forest Green border (2px) and white background.
- **Chips/Badges:** Used for ingredients (e.g., "High Protein," "Vegan"). These use the vibrant Lime Green background with Forest Green text for maximum legibility and "fresh" feel.
- **Progress Bars:** Use a thick, rounded track in Mint-White with a Forest Green or Lime Green indicator.
- **AI Feedback Tooltips:** Characterized by a soft Forest Green background with white text, using the `rounded-xl` shape to feel like speech bubbles.