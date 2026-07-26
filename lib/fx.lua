-- lib/fx.lua — Visual Effects Manager for Primordium City
-- Provides floating damage numbers, screen flashes, particles, and hitstop

local Tween = require("lib.tween")

local FX = {
    -- Floating text popups (damage numbers, status text)
    popups = {},
    -- Particle emitters
    particles = {},
    -- Screen flash overlay
    flash = { active = false, color = 0, alpha = 0, duration = 0, timer = 0 },
    -- Hitstop (frame freeze)
    hitstop = { active = false, frames = 0 },
    -- Persistent screen tint
    tint = { active = false, color = 0, alpha = 0 }
}

function FX.init()
    FX.popups = {}
    FX.particles = {}
    FX.flash = { active = false, color = 0, alpha = 0, duration = 0, timer = 0 }
    FX.hitstop = { active = false, frames = 0 }
    FX.tint = { active = false, color = 0, alpha = 0 }
end

--------------------------------------------------------------------
-- HITSTOP
--------------------------------------------------------------------

--- Freeze the game for N frames (call before update to skip updates)
---@return boolean true if game should skip this frame's update
function FX.should_freeze()
    if FX.hitstop.active then
        FX.hitstop.frames = FX.hitstop.frames - 1
        if FX.hitstop.frames <= 0 then
            FX.hitstop.active = false
        end
        return true
    end
    return false
end

--- Request a hitstop (frame freeze) for impact feel
function FX.request_hitstop(frames)
    FX.hitstop.active = true
    FX.hitstop.frames = frames or 3
end

--------------------------------------------------------------------
-- FLOATING TEXT / DAMAGE NUMBERS
--------------------------------------------------------------------

--- Spawn a floating damage number
function FX.damage_number(x, y, amount, color)
    color = color or gfx.COLOR_WHITE
    local popup = {
        text = tostring(math.floor(amount)),
        x = x + math.random(-4, 4),
        y = y,
        start_y = y,
        color = color,
        timer = 0,
        duration = 0.8,
        scale = 1.5,     -- starts big
        target_scale = 1.0,
        alpha = 1.0,
        world_space = true
    }
    table.insert(FX.popups, popup)
end

--- Spawn a floating heal number (green, rises slower)
function FX.heal_number(x, y, amount)
    local popup = {
        text = "+" .. tostring(math.floor(amount)),
        x = x + math.random(-2, 2),
        y = y,
        start_y = y,
        color = gfx.COLOR_GREEN,
        timer = 0,
        duration = 1.0,
        scale = 1.2,
        target_scale = 1.0,
        alpha = 1.0,
        world_space = true
    }
    table.insert(FX.popups, popup)
end

--- Spawn floating status text (PERFECT, MISS, CRITICAL, etc.)
function FX.text_popup(x, y, text, color, duration)
    local popup = {
        text = text,
        x = x,
        y = y,
        start_y = y,
        color = color or gfx.COLOR_YELLOW,
        timer = 0,
        duration = duration or 1.0,
        scale = 2.0,      -- starts big for emphasis
        target_scale = 1.0,
        alpha = 1.0,
        world_space = true
    }
    table.insert(FX.popups, popup)
end

--- Spawn floating text in screen space (for UI popups)
function FX.screen_popup(x, y, text, color, duration)
    local popup = {
        text = text,
        x = x,
        y = y,
        start_y = y,
        color = color or gfx.COLOR_WHITE,
        timer = 0,
        duration = duration or 1.0,
        scale = 1.0,
        target_scale = 1.0,
        alpha = 1.0,
        world_space = false
    }
    table.insert(FX.popups, popup)
end

--------------------------------------------------------------------
-- SCREEN FLASH
--------------------------------------------------------------------

--- Flash the entire screen with a color (e.g., white on hit, red on critical)
function FX.screen_flash(color, duration)
    FX.flash.active = true
    FX.flash.color = color or gfx.COLOR_WHITE
    FX.flash.duration = duration or 0.15
    FX.flash.timer = 0
    FX.flash.alpha = 1.0
end

--------------------------------------------------------------------
-- PARTICLES
--------------------------------------------------------------------

--- Spawn a burst of particles at position
function FX.spawn_particles(x, y, count, color, speed, lifetime)
    count = count or 8
    color = color or gfx.COLOR_WHITE
    speed = speed or 40
    lifetime = lifetime or 0.5
    
    for i = 1, count do
        local angle = (math.pi * 2 / count) * i + math.random() * 0.5
        local spd = speed * (0.5 + math.random() * 0.5)
        table.insert(FX.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd - 20, -- slight upward bias
            color = color,
            timer = 0,
            lifetime = lifetime * (0.7 + math.random() * 0.3),
            size = math.random(1, 2),
            world_space = true
        })
    end
end

--- Spawn glitch-style colored pixel particles
function FX.spawn_glitch_particles(x, y, count)
    count = count or 12
    local glitch_colors = {
        gfx.COLOR_RED, gfx.COLOR_GREEN, gfx.COLOR_BLUE,
        gfx.COLOR_YELLOW, gfx.COLOR_PINK, gfx.COLOR_WHITE
    }
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = 30 + math.random() * 50
        table.insert(FX.particles, {
            x = x + math.random(-8, 8),
            y = y + math.random(-8, 8),
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            color = glitch_colors[math.random(1, #glitch_colors)],
            timer = 0,
            lifetime = 0.3 + math.random() * 0.4,
            size = math.random(1, 3),
            world_space = true
        })
    end
end

--- Spawn impact sparks (directional, toward attacker)
function FX.spawn_impact(x, y, direction_x, count, color)
    count = count or 6
    color = color or gfx.COLOR_WHITE
    for i = 1, count do
        local angle = math.atan2(0, direction_x) + (math.random() - 0.5) * 1.5
        local spd = 40 + math.random() * 30
        table.insert(FX.particles, {
            x = x,
            y = y + math.random(-4, 4),
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd - 15,
            color = color,
            timer = 0,
            lifetime = 0.2 + math.random() * 0.2,
            size = 1,
            world_space = true
        })
    end
end

--------------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------------

function FX.update(dt)
    -- Update popups
    for i = #FX.popups, 1, -1 do
        local p = FX.popups[i]
        p.timer = p.timer + dt
        -- Rise upward
        p.y = p.start_y - (p.timer / p.duration) * 20
        -- Scale eases down
        local t = math.min(1.0, p.timer / (p.duration * 0.3))
        p.scale = p.scale + (p.target_scale - p.scale) * t * 0.15
        -- Fade out in last 30%
        local fade_start = p.duration * 0.7
        if p.timer > fade_start then
            p.alpha = 1.0 - ((p.timer - fade_start) / (p.duration * 0.3))
        end
        -- Remove when expired
        if p.timer >= p.duration then
            table.remove(FX.popups, i)
        end
    end
    
    -- Update particles
    for i = #FX.particles, 1, -1 do
        local p = FX.particles[i]
        p.timer = p.timer + dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 60 * dt -- gravity
        if p.timer >= p.lifetime then
            table.remove(FX.particles, i)
        end
    end
    
    -- Update screen flash
    if FX.flash.active then
        FX.flash.timer = FX.flash.timer + dt
        local progress = FX.flash.timer / FX.flash.duration
        FX.flash.alpha = math.max(0, 1.0 - progress)
        if FX.flash.timer >= FX.flash.duration then
            FX.flash.active = false
        end
    end
end

--------------------------------------------------------------------
-- DRAW (world-space, called within camera transform)
--------------------------------------------------------------------

function FX.draw_world()
    local cam_ox = Camera and Camera.ox or 0
    local cam_oy = Camera and Camera.oy or 0
    
    -- Draw world-space particles
    for _, p in ipairs(FX.particles) do
        if p.world_space then
            local alpha = 1.0 - (p.timer / p.lifetime)
            local sx = p.x - cam_ox
            local sy = p.y - cam_oy
            if p.size <= 1 then
                gfx.px(sx, sy, p.color, alpha)
            else
                gfx.rect_fill(sx, sy, p.size, p.size, p.color, alpha)
            end
        end
    end
    
    -- Draw world-space popups
    for _, p in ipairs(FX.popups) do
        if p.world_space then
            local sx = p.x - cam_ox
            local sy = p.y - cam_oy
            if p.scale > 1.05 then
                -- Draw scaled text using text_ex
                gfx.text_ex(p.text, sx + 1, sy + 1, p.scale, 0, gfx.COLOR_BLACK, p.alpha * 0.6)
                gfx.text_ex(p.text, sx, sy, p.scale, 0, p.color, p.alpha)
            else
                -- Draw normal text with shadow
                gfx.text(p.text, sx + 1, sy + 1, gfx.COLOR_BLACK, p.alpha * 0.6)
                gfx.text(p.text, sx, sy, p.color, p.alpha)
            end
        end
    end
end

--------------------------------------------------------------------
-- DRAW (screen-space, called after camera detach + shader reset)
--------------------------------------------------------------------

function FX.draw()
    -- Draw screen-space particles
    for _, p in ipairs(FX.particles) do
        if not p.world_space then
            local alpha = 1.0 - (p.timer / p.lifetime)
            if p.size <= 1 then
                gfx.px(p.x, p.y, p.color, alpha)
            else
                gfx.rect_fill(p.x, p.y, p.size, p.size, p.color, alpha)
            end
        end
    end
    
    -- Draw screen-space popups
    for _, p in ipairs(FX.popups) do
        if not p.world_space then
            if p.scale > 1.05 then
                gfx.text_ex(p.text, p.x + 1, p.y + 1, p.scale, 0, gfx.COLOR_BLACK, p.alpha * 0.6)
                gfx.text_ex(p.text, p.x, p.y, p.scale, 0, p.color, p.alpha)
            else
                gfx.text(p.text, p.x + 1, p.y + 1, gfx.COLOR_BLACK, p.alpha * 0.6)
                gfx.text(p.text, p.x, p.y, p.color, p.alpha)
            end
        end
    end
    
    -- Draw screen flash overlay
    if FX.flash.active and FX.flash.alpha > 0 then
        gfx.rect_fill(0, 0, usagi.GAME_W, usagi.GAME_H, FX.flash.color, FX.flash.alpha)
    end
end

return FX
