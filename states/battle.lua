-- states/battle.lua
local Timeline = require("battle.timeline")
local Party = require("systems.party")

local BattleState = {}
local VictoryScreen = require("battle.victory_screen")
local Inventory = require("systems.inventory")

function BattleState.enter(encounter_data)
    local enemy_db = usagi.read_json("enemies/arc1_enemies.json")
    local encounter_db = usagi.read_json("encounters/arc1_encounters.json")
    
    if type(encounter_data) == "string" and encounter_db and encounter_db.encounters then
        -- Find specific encounter by ID
        local found = nil
        for _, enc in ipairs(encounter_db.encounters) do
            if enc.id == encounter_data then
                found = enc
                break
            end
        end
        if found then
            local active_enemies = {}
            for _, enemy_id in ipairs(found.enemies) do
                local template = enemy_db.enemies[enemy_id]
                if template then
                    local e = {}
                    for k, v in pairs(template) do e[k] = v end
                    table.insert(active_enemies, e)
                end
            end
            encounter_data = { enemies = active_enemies, music = found.music }
        else
            encounter_data = nil
        end
    end

    if not encounter_data then
        if encounter_db and encounter_db.encounters and enemy_db and enemy_db.enemies then
            -- Collect encounters into a list
            local enc_list = {}
            for _, enc in pairs(encounter_db.encounters) do
                table.insert(enc_list, enc)
            end
            
            if #enc_list > 0 then
                local enc_def = enc_list[math.random(1, #enc_list)]
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
                encounter_data = { enemies = active_enemies, music = enc_def.music }
            end
        end
        if not encounter_data then
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
    if encounter_data and encounter_data.music then
        music.loop(encounter_data.music)
    else
        music.loop("theme")
    end
    
    VictoryScreen.init()
end

function BattleState.update(dt)
    Timeline.update(dt)
    
    if Timeline.state == "win" then
        if VictoryScreen.state == "inactive" then
            VictoryScreen.start(Timeline.combatants)
        end
        if VictoryScreen.update(dt) then
            for _, item in ipairs(VictoryScreen.items_dropped) do
                Inventory.add_item(item, 1)
            end
            Inventory.add_currency(VictoryScreen.cubes_earned)
            State.pop()
        end
    elseif Timeline.state == "lose" then
        if input.pressed(input.BTN1) then
            State.pop()
        end
    end
end

function BattleState.draw(dt)
    -- Draw battle background
    gfx.clear(gfx.COLOR_BLUE)
    
    Timeline.draw(dt)
    
    if Timeline.state == "win" then
        VictoryScreen.draw()
    elseif Timeline.state == "lose" then
        gfx.rect_fill(0, 0, usagi.GAME_W, usagi.GAME_H, gfx.COLOR_BLACK, 0.8)
        gfx.text_ex("GAME OVER", usagi.GAME_W / 2 - 40, usagi.GAME_H / 2 - 10, 2, 0, gfx.COLOR_RED, 1)
        gfx.text("Press [Z] to exit", usagi.GAME_W / 2 - 40, usagi.GAME_H / 2 + 20, gfx.COLOR_WHITE)
    end
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
