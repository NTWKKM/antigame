-- Primordium City RPG - Usagi Engine Entry Point

-- Global game state container (persists across reloads)
GameState = GameState or {}

-- Require engine components
State = require("engine.state_machine")
Camera = require("engine.camera")

-- Require game systems
Party = require("systems.party")
ResolutionDecay = require("systems.resolution_decay")
UXIndex = require("systems.ux_index")
QuestTracker = require("systems.quest_tracker")
SaveSystem = require("systems.save_system")

FX = require("lib.fx")
Tween = require("lib.tween")
Transition = require("engine.transition")

-- Require world components (stubs for now)
Player = require("world.player")

-- Global configuration
function _config()
  return {
    name = "Primordium City",
    game_id = "com.primordium.city",
    sprite_size = 16,
    game_width = 320,
    game_height = 180,
    pause_menu = true,
    pixel_perfect = false
  }
end

-- Initialize game
function _init()
  -- Load saved state if it exists
  if not SaveSystem.load() then
      -- Default new game state
      GameState = {
          res = 100, -- Resolution (0-100)
          ux = 0,    -- UX Index (0-100)
          party = {"elias"},
          inventory = {},
          flags = {}
      }
  end

  -- Register custom menu items if any
  usagi.menu_item("Save Game", function()
    SaveSystem.save()
  end)
  
  -- Initialize systems
  Camera.init()
  Party.init()
  ResolutionDecay.init()
  UXIndex.init()
  QuestTracker.init()
  State.init()
  FX.init()
  
  -- Start in EXPLORATION state for now
  State.push("EXPLORATION")
  
  -- Give starting items for testing in dev mode
  if usagi and usagi.IS_DEV then
    local Inventory = require("systems.inventory")
    Inventory.add_item("medkit", 5)
    Inventory.add_item("chrono_shard", 1)
    Inventory.add_item("aegis_core", 1)
  end
end

-- Update loop
function _update(dt)
  if FX.should_freeze() then return end
  ResolutionDecay.update(dt)
  UXIndex.update(dt)
  State.update(dt)
  Camera.update(dt)
  Tween.update(dt)
  FX.update(dt)
  Transition.update(dt)
end


-- Draw loop
function _draw(dt)
  -- Set post-process shader driven by Resolution stat
  gfx.shader_set("resolution_decay")
  gfx.shader_uniform("intensity", ResolutionDecay.get_shader_intensity())
  gfx.shader_uniform("u_time", usagi.elapsed or 0)

  -- Clear screen to black by default
  gfx.clear(gfx.COLOR_BLACK)
  
  -- Apply camera transform
  Camera.attach()
  
  -- Draw current state (which will draw map, characters, etc.)
  State.draw(dt)
  
  FX.draw_world()

  -- Detach camera for HUD and UI rendering
  Camera.detach()
  
  -- Reset shader before UI
  gfx.shader_set(nil)
  
  -- Draw HUD and UI overlays
  State.draw_ui(dt)
  FX.draw()
  Transition.draw()
end
