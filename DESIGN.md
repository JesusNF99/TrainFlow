# DESIGN SYSTEM: PREMIUM NEON MINIMAL

## 1. Core Theme & Vibe
- **Theme:** Dark Mode Only.
- **Vibe:** High-End Cyberpunk, tactical, minimalist. 
- **Philosophy:** Focus on depth, subtle atmospheric lighting, and extreme restraint with accent colors. The UI should feel like premium, matte-finished hardware.

## 2. Color Foundation
- **Background:** Deep Space Gray (`#121212`).
- **Surface (Cards/Modals):** Elevated Gray (`#1E1E1E`). Solid, no opacity.
- **Primary Text:** White (`#FFFFFF`) at `87%` opacity (reduces eye strain compared to pure white).
- **Secondary Text:** Muted Gray (`#A0A0A0`).
- **Primary Accent:** Electric Cyan (`#00F5FF`).
- **Secondary Accent:** Neon Lime (`#CCFF00`).

## 3. Lighting, Shadows & Depth
- **Hardware Edge Effect:** All `#1E1E1E` surfaces MUST have an inside stroke (inner border) of `1px` Pure White (`#FFFFFF`) at **5% to 8% opacity**. This simulates light catching the edge of a physical material.
- **Ambient Glows (No harsh blurs):** - Never apply a tight, solid glow to an element's border.
  - To make an element "emit" light, place a colored layer *behind* it: Blur `32px` to `48px`, Opacity `10%` to `15%`.
- **Shadows:** No traditional black drop-shadows. The difference between background and surface is enough.

## 4. Typography (Inter / Roboto / Google Sans)
- **Data & Timers:** Largest sizes. Primary Accent color. Regular or Light weight.
- **Headings (H1/H2):** Medium/Semi-Bold weight. Normal tracking (letter-spacing). Pure White (87%).
- **Overlines / Micro-labels:** ALL CAPS, Bold weight, **High Tracking (+1.5px to +2px)**. Muted Gray or Accent Color. *Never use high tracking on lowercase text.*
- **Body Text:** Regular weight. Normal tracking. Generous line-height (`140%` to `150%`) to create breathing room.

## 5. Key UI Components
- **Primary Action Buttons:**
  - Background: Transparent or `#1E1E1E`.
  - Text: Primary Accent (`#00F5FF`), Medium weight.
  - Border: `1px` solid Primary Accent at `30%` opacity.
  - Active/Pressed State: Background fills with Primary Accent at `10%` opacity. *Never fill 100%.*
- **Icons:** Thin outline style (e.g., `1.5px` stroke weight). Never use filled/solid icons.
- **Progress/Success States:** Use Secondary Accent (`#CCFF00`). Keep strokes thin (`2px` to `3px` max for progress bars).