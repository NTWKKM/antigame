# Design System & UI Specifications — Primordium City

## Target Display Parameters
- **Canvas Resolution**: 320 × 180 pixels (16:9 native low-res pixel art).
- **Tile Dimensions**: 16 × 16 pixels.
- **Font & Rendering**: Monospaced/Pixel font, crisp 1px borders, shadow offset (1, 1).

## Color Tokens (Usagi GFX Engine Colors)
- `gfx.COLOR_BLACK`: `0x000000` (Background clearing & text shadows)
- `gfx.COLOR_WHITE`: `0xFFFFFF` (Primary text & clean elements)
- `gfx.COLOR_YELLOW`: `0xFFFF00` (Quest headers & active highlights)
- `gfx.COLOR_GREEN`: `0x00FF00` (Pristine state indicator & positive stats)
- `gfx.COLOR_RED`: `0xFF0000` (High UX warning & critical RES alert)
- `gfx.COLOR_BLUE`: `0x29ADFF` (Tech & sync indicators)

## Resolution Visual Thresholds
| RES Range | Status Label | Shader Distortion | HUD Accent | Visual FX |
|---|---|---|---|---|
| 75% - 100% | Pristine | 0.00 – 0.25 | Green | Clear, stable pixels |
| 50% - 74%  | Degrading | 0.25 – 0.50 | Yellow | Minor RGB chromatic aberration |
| 25% - 49%  | Bit Rot   | 0.50 – 0.75 | Orange | Periodic noise lines & jitter |
| 0% - 24%   | Dead Zone | 0.75 – 1.00 | Flashing Red | Heavy glitching & color bleed |

## UI States & HUD Layout
- **Top-Left Header**:
  - Line 1: `RES: XX%` (White text with black shadow)
  - Line 2: `UX:  XX%` (Yellow under 80%, Red above 80%)
- **Top-Right Header**:
  - Line 1: Current Chapter Name (Yellow)
  - Line 2: `[Resolution State]` (Color mapped by threshold)
- **Overlay Notification Banner**:
  - Centered at (Y=85), 20px high dark banner with centered flashing red text during UXI Anomaly triggers.
