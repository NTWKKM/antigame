-- states/exploration.lua
local Tilemap = require("world.tilemap")
local Player = require("world.player")
local NPCManager = require("world.npc")
local HUD = require("ui.hud")
local DialogueBox = require("ui.dialogue_box")
local MenuScreen = require("ui.menu_screen")

local ExplorationState = {
    step_counter = 0,
    encounter_rate = 80 -- steps before random encounter check
}

function ExplorationState.enter(map_name)
    -- Default to sector 7 slums if no map provided
    local target_map = map_name or "sector_7_slums"
    
    Tilemap.init()
    Tilemap.load(target_map)
    NPCManager.load_map_npcs(target_map)
    Player.init(160, 224)
    ExplorationState.step_counter = 0
    
    -- Play exploration music (file stem only, loop it)
    music.loop("theme")
end

function ExplorationState.update(dt)
    -- If menu or dialogue is active, update those instead
    if MenuScreen.active then
        MenuScreen.update(dt)
        return
    end
    if DialogueBox.active then
        DialogueBox.update(dt)
        return
    end

    Player.update(dt)
    NPCManager.update(dt)
    
    -- Check walk-over triggers
    local trigger = NPCManager.check_trigger(Player.x, Player.y, Player.w, Player.h)
    if trigger then
        if not trigger.quest_step or (QuestTracker and QuestTracker.chapter == trigger.quest_step) then
            if trigger.run_once then trigger.active = false end
            -- Load dialogue tree from JSON
            local dfile, dnode = trigger.dialogue_id:match("([^:]+):?([^:]*)")
            dnode = (dnode == "") and dfile or dnode
            if dfile and dfile ~= "" then
                local data = usagi.read_json("dialogue/" .. dfile .. ".json")
                if data and data.dialogue then
                    DialogueBox.start_tree(data.dialogue, dnode)
                end
            end
        end
    end
    
    -- Interaction handling (BTN1 = Z key / gamepad south)
    if input.pressed(input.BTN1) then
        local npc = NPCManager.check_interaction(Player.x, Player.y, Player.facing)
        if npc and npc.dialogue_id and npc.dialogue_id ~= "" then
            sfx.play("select")
            local dfile, dnode = npc.dialogue_id:match("([^:]+):?([^:]*)")
            dnode = (dnode == "") and dfile or dnode
            local data = usagi.read_json("dialogue/" .. dfile .. ".json")
            if data and data.dialogue then
                DialogueBox.start_tree(data.dialogue, dnode)
            end
        end
    end
    
    -- Pause Menu (BTN3 = C key / gamepad north)
    if input.pressed(input.BTN3) then
        MenuScreen.toggle()
    end

    -- Step counter for random encounters
    if Player.is_moving then
        ExplorationState.step_counter = ExplorationState.step_counter + dt * 60
        if ExplorationState.step_counter >= ExplorationState.encounter_rate then
            ExplorationState.step_counter = 0
            -- 30% chance of encounter per threshold
            if math.random() < 0.30 then
                State.switch("BATTLE")
            end
        end
    end
    
    -- Camera follows player
    Camera.follow(Player.x + Player.w/2, Player.y + Player.h/2)
    Camera.set_bounds(0, 0, Tilemap.width * Tilemap.tile_size, Tilemap.height * Tilemap.tile_size)
end

function ExplorationState.draw(dt)
    -- Map layer
    Tilemap.draw()
    
    -- Entity layer (sort by Y later, for now just draw NPCs then Player)
    NPCManager.draw()
    Player.draw()
end

function ExplorationState.draw_ui(dt)
    -- HUD overlay
    HUD.draw()
    
    -- Dialogue box overlay
    DialogueBox.draw()
    
    -- Menu overlay
    MenuScreen.draw()
end

function ExplorationState.exit()
    music.stop()
end

return ExplorationState
