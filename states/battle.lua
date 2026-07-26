-- states/battle.lua
local Timeline = require("battle.timeline")
local Party = require("systems.party")

local BattleState = {}

function BattleState.enter(encounter_data)
    -- If no encounter passed, do a default test fight
    encounter_data = encounter_data or {
        enemies = {
            {id = "drone_01", name = "Security Drone", hp = 30, max_hp = 30, atk = 8, def = 5, spd = 8, skills = {"shoot"}}
        }
    }
    
    local party_data = Party.get_active_stats()
    
    Timeline.init(party_data, encounter_data.enemies)
    
    -- Play battle music (file stem only, loop)
    music.loop("theme")
end

function BattleState.update(dt)
    Timeline.update(dt)
    
    -- If win/loss and user presses BTN1, return to exploration
    if (Timeline.state == "win" or Timeline.state == "lose") and input.pressed(input.BTN1) then
        State.switch("EXPLORATION")
    end
end

function BattleState.draw(dt)
    -- Draw battle background
    gfx.clear(gfx.COLOR_BLUE)
    
    Timeline.draw(dt)
end

function BattleState.draw_ui(dt)
    
end

function BattleState.exit()
    music.stop()
end

return BattleState
