local anim = require("lib.anim")

local entity = {}
entity.__index = entity

function entity.new(x, y, w, h)
    local self = setmetatable({}, entity)
    self.x = x or 0
    self.y = y or 0
    self.width = w or 16
    self.height = h or 16
    self.vx = 0
    self.vy = 0
    self.state = "idle"
    self.animations = {}
    return self
end

function entity:add_animation(name, frames, speed, loop)
    self.animations[name] = anim.new(frames, speed, loop)
end

function entity:set_state(state)
    if self.state ~= state then
        self.state = state
        if self.animations[state] then
            self.animations[state]:reset()
        end
    end
end

function entity:update(dt)
    if self.animations[self.state] then
        self.animations[self.state]:update(dt)
    end
end

function entity:draw()
    if self.animations[self.state] then
        local frame = self.animations[self.state]:get_frame()
        -- draw sprite frame (assuming sprite 0 for placeholder)
        gfx.sprite(frame, self.x, self.y)
    else
        gfx.rect_fill(self.x, self.y, self.width, self.height, 8)
    end
end

return entity
