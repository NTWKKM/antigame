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
    self.tp = stats.tp or 50
    self.max_tp = stats.max_tp or 50
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
    
    self.home_x = 0
    self.home_y = 0
    self.draw_x = 0
    self.draw_y = 0
    self.shake_x = 0
    self.shake_y = 0
    self.hp_display = self.hp
    self.atb_display = 0
    self.death_timer = 0
    
    return self
end

function Combatant:update_atb(dt)
    -- Interpolate display values
    self.hp_display = self.hp_display + (self.hp - self.hp_display) * 10 * dt
    self.atb_display = self.atb_display + (self.atb - self.atb_display) * 10 * dt
    
    -- Decay shake
    self.shake_x = self.shake_x * (1 - math.min(1, dt * 10))
    self.shake_y = self.shake_y * (1 - math.min(1, dt * 10))

    if self.flash_timer > 0 then
        self.flash_timer = self.flash_timer - dt
    end
    if self.state == "dead" then
        if self.death_timer > 0 then
            self.death_timer = self.death_timer - dt
        end
        return
    end
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
    
    self.shake_x = math.random(-3, 3)
    
    if self.hp <= 0 then
        self.hp = 0
        self.state = "dead"
        self.atb = 0
        self.death_timer = 0.5
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

function Combatant:is_visible()
    return self.state ~= "dead" or self.death_timer > 0
end

return Combatant
