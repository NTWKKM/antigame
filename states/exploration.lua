-- states/exploration.lua
local Tilemap = require("world.tilemap")
local Player = require("world.player")
local NPCManager = require("world.npc")
local HUD = require("ui.hud")
local DialogueBox = require("ui.dialogue_box")
local MenuScreen = require("ui.menu_screen")
local Transition = require("engine.transition")

local ExplorationState = {
    step_counter = 0,
    encounter_rate = 80 -- steps before random encounter check
}

function ExplorationState.enter(map_name, spawn_x, spawn_y, facing)
    local target_map = map_name or "sector_7_slums"
    ExplorationState.current_map = target_map
    
    Tilemap.init()
    Tilemap.load(target_map)
    NPCManager.load_map_npcs(target_map)
    
    local px = spawn_x or 160
    local py = spawn_y or 224
    Player.init(px, py)
    if facing then Player.facing = facing end
    
    ExplorationState.step_counter = 0
    ExplorationState.is_transitioning = false
    
    music.loop("theme")
end

function ExplorationState.trigger_edge_transition(direction)
    local connections = {
        sector_7_slums = { north = "sector_7_north", east = "sector_7_east" },
        sector_7_north = { south = "sector_7_slums", north = "substation_07" },
        sector_7_east = { west = "sector_7_slums" },
        substation_07 = { south = "sector_7_north", north = "sector_4_streets" },
        sector_4_streets = { south = "substation_07", north = "node_core_01" },
        node_core_01 = { south = "sector_4_streets" }
    }
    local cmap = ExplorationState.current_map
    local map_w = Tilemap.width * Tilemap.tile_size
    local map_h = Tilemap.height * Tilemap.tile_size

    if not connections[cmap] or not connections[cmap][direction] then
        -- Block movement
        if direction == "west" then Player.x = 0
        elseif direction == "east" then Player.x = map_w - Player.w
        elseif direction == "north" then Player.y = 0
        elseif direction == "south" then Player.y = map_h - Player.h
        end
        return
    end
    
    local next_map = connections[cmap][direction]
    ExplorationState.is_transitioning = true
    
    Transition.start("fade_out", 3.0, function()
        Tilemap.load(next_map)
        local nmap_w = Tilemap.width * Tilemap.tile_size
        local nmap_h = Tilemap.height * Tilemap.tile_size
        
        local nx, ny = Player.x, Player.y
        if direction == "west" then nx = nmap_w - Player.w - 8
        elseif direction == "east" then nx = 8
        elseif direction == "north" then ny = nmap_h - Player.h - 8
        elseif direction == "south" then ny = 8
        end
        
        ExplorationState.current_map = next_map
        NPCManager.load_map_npcs(next_map)
        Player.x = nx
        Player.y = ny
        ExplorationState.is_transitioning = false
        Transition.start("fade_in", 3.0)
    end)
end

function ExplorationState.update(dt)
    if MenuScreen.active then
        MenuScreen.update(dt)
        return
    end
    if DialogueBox.active then
        DialogueBox.update(dt)
        return
    end
    if ExplorationState.is_transitioning then
        return
    end

    Player.update(dt)
    NPCManager.update(dt)
    
    -- Check edge transitions
    local map_w = Tilemap.width * Tilemap.tile_size
    local map_h = Tilemap.height * Tilemap.tile_size
    if Player.x < -4 then ExplorationState.trigger_edge_transition("west")
    elseif Player.x > map_w - Player.w + 4 then ExplorationState.trigger_edge_transition("east")
    elseif Player.y < -4 then ExplorationState.trigger_edge_transition("north")
    elseif Player.y > map_h - Player.h + 4 then ExplorationState.trigger_edge_transition("south")
    end
    
    if ExplorationState.is_transitioning then return end
    
    local trigger = NPCManager.check_trigger(Player.x, Player.y, Player.w, Player.h)
    if trigger then
        if trigger.is_warp then
            ExplorationState.is_transitioning = true
            Transition.start("iris_out", 2.0, function()
                ExplorationState.enter(trigger.target_map, trigger.target_x, trigger.target_y)
                Transition.start("iris_in", 2.0)
            end)
        elseif not trigger.quest_step or (QuestTracker and QuestTracker.chapter == trigger.quest_step) then
            if trigger.run_once then trigger.active = false end
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
                Transition.start("iris_out", 1.0, function() State.push("BATTLE") end)
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
    
    -- Entity layer (sort by Y)
    local entities = {}
    table.insert(entities, {y = Player.y, obj = Player})
    for _, npc in ipairs(NPCManager.npcs) do
        if npc.active then
            table.insert(entities, {y = npc.y, obj = npc})
        end
    end
    
    table.sort(entities, function(a, b) return a.y < b.y end)
    
    for _, entity in ipairs(entities) do
        if entity.obj == Player then
            Player.draw()
        else
            entity.obj:draw()
        end
    end
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
