-- world/npc.lua
local Tilemap = require("world.tilemap")

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
    return self
end

function NPC:update(dt)
    -- NPCs could wander here
end

function NPC:draw()
    if not self.active then return end
    -- Draw shadow
    gfx.rect_fill(self.x - (Camera.ox or 0) + 2, self.y - (Camera.oy or 0) + 12, 12, 4, gfx.COLOR_BLACK)
    -- Draw sprite
    gfx.spr(self.sprite_id, self.x - (Camera.ox or 0), self.y - (Camera.oy or 0))
end

-- NPC Manager
local NPCManager = {
    npcs = {}
}

function NPCManager.load_map_npcs(map_name)
    NPCManager.npcs = {}
    
    if Tilemap.objects then
        for _, obj in ipairs(Tilemap.objects) do
            if obj.type == "npc" or obj.type == "trigger" then
                local sprite = 0
                local dialogue_id = ""
                if obj.properties then
                    sprite = obj.properties.sprite_id or 0
                    dialogue_id = obj.properties.dialogue_id or ""
                end
                
                local npc = NPC.new(obj.name, obj.name, obj.x, obj.y, sprite, dialogue_id)
                npc.w = obj.width or 16
                npc.h = obj.height or 16
                npc.is_trigger = (obj.type == "trigger")
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
