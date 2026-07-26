# Architecture Overview — Primordium City (Usagi Engine)

## Components

1. **Engine Layer (`engine/`)**:
   - `state_machine.lua`: Global state manager handling transitions (`EXPLORATION`, `BATTLE`) and delegation of update/draw hooks.
   - `camera.lua`: Smooth tracking camera with deadzone clamping and screen shake dynamics.
   - `timer.lua`: Frame-independent timer utility for delayed actions and animations.

2. **Game Systems Layer (`systems/`)**:
   - `resolution_decay.lua`: Core reality integrity system (`GameState.res` 0-100) driving post-processing shader distortion and reality collapse.
   - `ux_index.lua`: Unpredictability Index tracker (`GameState.ux` 0-100) managing chaos accumulation and anomaly triggers.
   - `quest_tracker.lua`: Story chapter progression tracker managing narrative phases across 20 chapters and 4 acts.
   - `party.lua`: Active party composition, stat calculations, and status buff applications.
   - `inventory.lua`: Item storage and usage resolution.
   - `save_manager.lua`: Persistence interface wrapping `usagi.save()` / `usagi.load()`.

3. **Battle System Layer (`battle/`)**:
   - `timeline.lua`: Active Time Battle (ATB) queue controller, managing turn priority and combat state flow.
   - `timeline_actions.lua`: Modular action execution engine handling Attacks, Skills, Items, Sync Techs, and enemy AI turns.
   - `combatant.lua`: Battle entity representation containing stats, ATB progress, and status effects.
   - `resolution_gauge.lua`: Tactical combat gauge modifying damage output and defense based on RES state.
   - `reactive_defense.lua`: Quick-time event (QTE) defensive mechanics during enemy turns.
   - `sync_tech.lua`: Team synergy ability calculations and execution.

4. **World & UI Layer (`world/`, `ui/`)**:
   - `tilemap.lua` / `player.lua` / `npc.lua`: Map loader, entity collision, grid movement, and interaction triggers.
   - `hud.lua` / `dialogue_box.lua` / `menu_screen.lua`: Screen-space UI components rendered outside camera transform.

## Data Flow

1. **Game Loop Pipeline**:
   - `main.lua _update(dt)` -> System updates (`ResolutionDecay`, `UXIndex`) -> `State.update(dt)` -> `Camera.update(dt)`.
   - `main.lua _draw(dt)` -> Shader bind (`gfx.shader_set("resolution_decay")`) -> Camera attach -> State world rendering -> Camera detach -> Shader unbind -> UI overlay rendering (`State.draw_ui(dt)`).

2. **Resolution & Distortion Pipeline**:
   - Systems or actions call `ResolutionDecay.modify(amount)`.
   - `GameState.res` updates (clamped 0-100).
   - In `_draw(dt)`, `ResolutionDecay.get_shader_intensity()` computes continuous shader parameter `1.0 - (GameState.res / 100.0)`.
   - HUD queries `ResolutionDecay.get_resolution_state()` to display current narrative state ("Pristine", "Degrading", "Bit Rot", "Dead Zone").

3. **UX Index & Anomaly Event Flow**:
   - Combat actions or rule-breaking choices invoke `UXIndex.add(amount)`.
   - When `GameState.ux` hits 100, `UXIndex.trigger_anomaly()` activates:
     - Applies camera shake via `Camera.shake(5, 0.6)`.
     - Plays glitch audio feedback.
     - Deducts 10 RES via `ResolutionDecay.modify(-10)`.
     - Resets/reduces UX to prevent infinite trigger loops.
     - Displays transient HUD notification banner.

## Architectural Decisions

1. **ADR-001: Single Source of Truth for Resolution State**:
   - **Context**: Dual resolution intensity calculations previously existed in `ResolutionDecay` and `QuestTracker`.
   - **Decision**: `GameState.res` (0-100) is the sole numeric source of truth for reality integrity. Narrative resolution states ("Pristine", "Degrading", "Bit Rot", "Dead Zone") are derived dynamically from `GameState.res` and chapter bounds, while shader intensity is calculated smoothly from `GameState.res`.

2. **ADR-002: Modularization of Battle Timeline Logic**:
   - **Context**: `battle/timeline.lua` exceeded 450 lines combining ATB timing, player input menus, combat resolution, and QTEs.
   - **Decision**: Decouple action resolution and enemy AI into `battle/timeline_actions.lua` while preserving ATB loop management in `battle/timeline.lua`.

3. **ADR-003: Environment-Guarded Development Initializers**:
   - **Context**: Debug item injection in `main.lua` threatened production save state purity.
   - **Decision**: All developer testing shortcuts must be explicitly guarded behind `if usagi and usagi.IS_DEV then` blocks.
