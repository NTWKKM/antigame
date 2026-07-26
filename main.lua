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

-- Require world components (stubs for now)
-- Player = require("world.player")

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
  local saved_data = usagi.load()
  if saved_data then
      GameState = saved_data
  else
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
    usagi.save(GameState)
  end)
  
  -- Initialize systems
  Camera.init()
  Party.init()
  ResolutionDecay.init()
  UXIndex.init()
  State.init()
  
  -- Start in EXPLORATION state for now
  State.switch("EXPLORATION")
  
  -- Give starting items for testing
  local Inventory = require("systems.inventory")
  Inventory.add_item("medkit", 5)
  Inventory.add_item("chrono_shard", 1)
  Inventory.add_item("aegis_core", 1)
end

-- Update loop
function _update(dt)
  State.update(dt)
  Camera.update(dt)
end

-- Draw loop
function _draw(dt)
  -- Set post-process shader driven by Resolution stat
  gfx.shader_set("resolution_decay")
  gfx.shader_uniform("intensity", ResolutionDecay.get_shader_intensity())

  -- Clear screen to black by default
  gfx.clear(gfx.COLOR_BLACK)
  
  -- Apply camera transform
  Camera.attach()
  
  -- Draw current state (which will draw map, characters, etc.)
  State.draw(dt)
  
  -- Detach camera for HUD and UI rendering
  Camera.detach()
  
  -- Reset shader before UI
  gfx.shader_set(nil)
  
  -- Draw HUD and UI overlays
  State.draw_ui(dt)
end
