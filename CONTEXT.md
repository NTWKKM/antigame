# Project Context — Primordium City

## Glossary

- **RES (Resolution)**: A core metric representing the structural integrity of reality in Primordium City (0% to 100%). Lower RES causes visual pixel distortion shaders, severe atmospheric anomalies, and harsher combat conditions.
- **UXI (Unpredictability Index)**: A meter measuring chaos accumulated through over-reliance on high-tier skills or reality manipulation (0% to 100%). Reaching 100% triggers spontaneous reality anomalies.
- **Usagi Engine**: A lightweight 2D pixel-art RPG engine designed for 320x180 resolution rapid prototyping using Lua 5.5, supporting live-reload, custom shaders, and tilemaps.
- **Sector 7**: The starting dystopian slum district, heavily degraded and prone to low RES anomalies.
- **Sync Tech**: Combined battle abilities executed by paired party members.

## Architectural Decision Records (ADR)

### ADR-001: Unified Resolution Integrity Model
- **Status**: Accepted
- **Impact**: All systems query `GameState.res` for resolution mechanics. `QuestTracker` bounds target thresholds but does not calculate independent shader values.

### ADR-002: Modular Battle Action Dispatcher
- **Status**: Accepted
- **Impact**: Combat actions (Attack, Skill, Sync, Item, Defense) are isolated into `battle/timeline_actions.lua` to maintain low cognitive load and file sizes under 200 lines.
