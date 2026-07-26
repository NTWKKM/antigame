-- states/battle.lua
local Timeline = require("battle.timeline")
local Party = require("systems.party")

local BattleState = {}

function BattleState.enter(encounter_data)
    if not encounter_data then
        local enemy_db = usagi.read_json("enemies.json")
        if enemy_db and enemy_db.encounters and enemy_db.enemies then
            -- Select a random encounter
            local enc_def = enemy_db.encounters[math.random(1, #enemy_db.encounters)]
            local active_enemies = {}
            for _, enemy_id in ipairs(enc_def.enemies) do
                local template = enemy_db.enemies[enemy_id]
                if template then
                    -- Shallow copy template
                    local e = {}
                    for k, v in pairs(template) do e[k] = v end
                    table.insert(active_enemies, e)
                end
            end
            encounter_data = { enemies = active_enemies }
        else
            encounter_data = {
                enemies = {
                    {id = "drone_01", name = "Security Drone", hp = 45, max_hp = 45, atk = 12, def = 8, spd = 10, skills = {"shoot"}}
                }
            }
        end
    end
    
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
    local Party = require("systems.party")
    local Timeline = require("battle.timeline")
    for _, c in ipairs(Timeline.combatants) do
        if not c.is_enemy then
            Party.update_member_status(c.id, c.hp, c.tp)
        end
    end
end

return BattleState
