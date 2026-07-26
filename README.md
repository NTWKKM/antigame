# Primordium City (antigame)

> A Cyberpunk / Dystopian RPG built on the **Usagi Engine** (Lua 5.5, 320×180 pixel-art, live-reload engine).

---

## 🌆 Overview

**Primordium City** is an offline-first 2D pixel-art RPG exploring themes of reality degradation and system instability in a dystopian cyberpunk megalopolis. As the city's structural code decays, players navigate glitched sectors, manage chaotic abilities, and uncover the truth behind the Node.

## ⚡ Key Game Mechanics

- **Resolution (RES)**: Measures the structural integrity of reality (0% - 100%). As RES decays over time or through environmental hazards, custom shader distortion effects intensify, warping the screen and introducing reality anomalies.
- **Unpredictability Index (UXI)**: Measures accumulated chaos from using powerful combat skills or bending game rules. High UXI triggers spontaneous screen-shaking anomalies, enemy power spikes, and environmental hazards.
- **Active Time Battle (ATB) & Sync Tech**: Dynamic combat featuring turn-based timeline meters, quick-time event (QTE) reactive defense, and party synergy combination attacks.
- **20-Chapter Narrative Arc**: Spanning 4 distinct Acts across Sector 7 Slums, Sunken Archives, Mid-Sectors, and the Dead Zone Node.

## 🛠 Project Structure

```
antigame/
├── engine/             # State machine, camera tracking, timer utilities
├── systems/            # Game logic (RES decay, UXI, quests, party, inventory, saves)
├── battle/             # ATB timeline controller, combatants, QTE defense, sync tech
├── world/              # Tilemap loaders, player movement, NPC triggers & dialogues
├── ui/                 # HUD, dialogue boxes, pause menus
├── states/             # State machine states (EXPLORATION, BATTLE)
├── shaders/            # Post-processing pixel distortion GLSL shaders
├── data/               # Story dialogues, maps, item data
├── main.lua            # Usagi engine entry point & system initializers
├── ARCHITECTURE.md     # System architecture & ADR specifications
└── USAGI.md            # Usagi Engine documentation & API reference
```

## 🎮 Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | Arrow Keys / WASD | D-Pad / Left Stick |
| Interact / Confirm | Z | Button 1 (South) |
| Cancel / Back | X | Button 2 (East) |
| Menu / Pause | C | Button 3 (North) |

## 🚀 Running Locally

This game runs inside the **Usagi Engine**.

1. Launch Usagi Engine pointing to the `antigame` directory:
   ```bash
   usagi .
   ```
2. Hot-reloading is active: edits to `.lua` files update instantly in-game.

## 📄 License

MIT License.
