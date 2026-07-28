-- world/npc.lua
local Tilemap = require("world.tilemap")
local Player = require("world.player")

local NPC = {}
NPC.__index = NPC

function NPC.new(id, name, x, y, sprite_id, dialogue_id)
    local self = setmetatable({}, NPC)
    self.id = id
    self.name = name
    self.x = x
    self.y = y
    self.w = 16
    self.h = 16
    self.sprite_id = sprite_id
    self.dialogue_id = dialogue_id
    self.active = true
    self.wander_timer = math.random(2, 5)
    self.show_prompt = false
    return self
end

function NPC:update(dt)
    if self.is_trigger or not self.active then return end
    self.wander_timer = self.wander_timer - dt
    if self.wander_timer <= 0 then
        local dx = math.random(-1, 1)
        local dy = math.random(-1, 1)
        self.x = self.x + dx * dt * 20
        self.y = self.y + dy * dt * 20
        self.wander_timer = math.random(2, 5)
    end
end

function NPC:draw()
    if not self.active then return end
    -- Draw shadow
    gfx.rect_fill(self.x - (Camera.ox or 0) + 2, self.y - (Camera.oy or 0) + 12, 12, 4, gfx.COLOR_BLACK)
    -- Draw sprite
    gfx.spr(self.sprite_id, self.x - (Camera.ox or 0), self.y - (Camera.oy or 0))
    if self.show_prompt then
        gfx.text("!", self.x - (Camera.ox or 0), self.y - (Camera.oy or 0) - 10, gfx.COLOR_YELLOW)
    end
end

-- NPC Manager
local NPCManager = {
    npcs = {}
}

function NPCManager.load_map_npcs(map_name)
    NPCManager.npcs = {}
    
    if Tilemap.objects then
        for _, obj in ipairs(Tilemap.objects) do
            if obj.type == "npc" or obj.type == "trigger" or obj.type == "warp" then
                local sprite = 0
                local dialogue_id = ""
                if obj.properties then
                    sprite = obj.properties.sprite_id or 0
                    dialogue_id = obj.properties.dialogue_id or ""
                end
                
                local npc = NPC.new(obj.name, obj.name, obj.x, obj.y, sprite, dialogue_id)
                npc.w = obj.width or 16
                npc.h = obj.height or 16
                npc.is_trigger = (obj.type == "trigger" or obj.type == "warp")
                
                if obj.type == "warp" then
                    npc.is_warp = true
                    if obj.properties then
                        npc.target_map = obj.properties.target_map
                        npc.target_x = obj.properties.target_x or 16
                        npc.target_y = obj.properties.target_y or 16
                    end
                end
                
                if obj.properties and obj.properties.run_once then
                    npc.run_once = true
                end
                if obj.properties and obj.properties.quest_step then
                    npc.quest_step = obj.properties.quest_step
                end
                
                table.insert(NPCManager.npcs, npc)
            end
        end
    end
end

function NPCManager.update(dt)
    for _, npc in ipairs(NPCManager.npcs) do
        npc:update(dt)
        if not npc.is_trigger and npc.active then
            local dist = math.abs(npc.x - Player.x) + math.abs(npc.y - Player.y)
            npc.show_prompt = (dist < 24)
        end
    end
end

function NPCManager.draw()
    for _, npc in ipairs(NPCManager.npcs) do
        npc:draw()
    end
end

function NPCManager.check_interaction(px, py, facing)
    -- Check if an NPC is in the tile the player is facing
    local check_x, check_y = px, py
    if facing == "up" then check_y = py - 16
    elseif facing == "down" then check_y = py + 16
    elseif facing == "left" then check_x = px - 16
    elseif facing == "right" then check_x = px + 16
    end
    
    local hitbox = { left = check_x, right = check_x + 16, top = check_y, bottom = check_y + 16 }
    
    for _, npc in ipairs(NPCManager.npcs) do
        if npc.active and not npc.is_trigger and
           npc.x < hitbox.right and npc.x + npc.w > hitbox.left and
           npc.y < hitbox.bottom and npc.y + npc.h > hitbox.top then
            return npc
        end
    end
    return nil
end

function NPCManager.check_trigger(px, py, pw, ph)
    local hitbox = { left = px, right = px + pw, top = py, bottom = py + ph }
    for _, npc in ipairs(NPCManager.npcs) do
        if npc.active and npc.is_trigger and
           npc.x < hitbox.right and npc.x + npc.w > hitbox.left and
           npc.y < hitbox.bottom and npc.y + npc.h > hitbox.top then
            return npc
        end
    end
    return nil
end

return NPCManager
