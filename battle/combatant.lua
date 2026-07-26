-- battle/combatant.lua
local Combatant = {}
Combatant.__index = Combatant

function Combatant.new(id, name, is_enemy, stats)
    local self = setmetatable({}, Combatant)
    self.id = id
    self.name = name
    self.is_enemy = is_enemy
    self.hp = stats.hp or 100
    self.max_hp = stats.max_hp or 100
    self.atk = stats.atk or 10
    self.def = stats.def or 10
    self.spd = stats.spd or 10
    self.skills = stats.skills or {}
    
    -- Battle state
    self.atb = 0
    self.atb_max = 1000
    self.state = "idle" -- idle, ready, acting, dead
    self.action_queue = nil
    self.flash_timer = 0
    
    return self
end

function Combatant:update_atb(dt)
    if self.flash_timer > 0 then
        self.flash_timer = self.flash_timer - dt
    end
    if self.state == "dead" then return end
    if self.state == "idle" then
        -- Fill ATB based on speed
        self.atb = self.atb + (self.spd * dt * 50)
        if self.atb >= self.atb_max then
            self.atb = self.atb_max
            self.state = "ready"
        end
    end
end

function Combatant:take_damage(amount)
    -- amount parameter is raw attack power (or scaled skill power)
    local mit_factor = 100 / (100 + math.max(0, self.def))
    local actual_damage = math.max(1, math.floor(amount * mit_factor))
    self.hp = self.hp - actual_damage
    self.flash_timer = 0.2 -- Flash for 0.2s
    if self.hp <= 0 then
        self.hp = 0
        self.state = "dead"
        self.atb = 0
    end
    return actual_damage
end

function Combatant:heal(amount)
    self.hp = self.hp + amount
    if self.hp > self.max_hp then self.hp = self.max_hp end
end

function Combatant:reset_atb()
    self.atb = 0
    self.state = "idle"
end

return Combatant
