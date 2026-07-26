-- engine/camera.lua
local Camera = {
    x = 0,
    y = 0,
    target_x = 0,
    target_y = 0,
    shake_amount = 0,
    shake_duration = 0,
    bounds = { x1 = 0, y1 = 0, x2 = 1000, y2 = 1000 },
    deadzone = { w = 32, h = 32 }
}

function Camera.init()
    Camera.x = 0
    Camera.y = 0
    Camera.target_x = 0
    Camera.target_y = 0
    Camera.shake_amount = 0
    Camera.shake_duration = 0
end

function Camera.follow(tx, ty)
    Camera.target_x = tx
    Camera.target_y = ty
end

function Camera.set_bounds(x1, y1, x2, y2)
    Camera.bounds.x1 = x1
    Camera.bounds.y1 = y1
    Camera.bounds.x2 = x2
    Camera.bounds.y2 = y2
end

function Camera.shake(amount, duration)
    Camera.shake_amount = amount
    Camera.shake_duration = duration
end

function Camera.update(dt)
    -- Calculate target camera position (centered on target)
    local ideal_x = Camera.target_x - usagi.GAME_W / 2
    local ideal_y = Camera.target_y - usagi.GAME_H / 2
    
    -- Smooth approach (lerp)
    if util and util.approach then
        Camera.x = util.approach(Camera.x, ideal_x, 100 * dt)
        Camera.y = util.approach(Camera.y, ideal_y, 100 * dt)
    else
        -- Fallback if util not available
        Camera.x = Camera.x + (ideal_x - Camera.x) * 5 * dt
        Camera.y = Camera.y + (ideal_y - Camera.y) * 5 * dt
    end
    
    -- Clamp to bounds
    local max_x = Camera.bounds.x2 - usagi.GAME_W
    local max_y = Camera.bounds.y2 - usagi.GAME_H
    if max_x < Camera.bounds.x1 then max_x = Camera.bounds.x1 end
    if max_y < Camera.bounds.y1 then max_y = Camera.bounds.y1 end
    
    if Camera.x < Camera.bounds.x1 then Camera.x = Camera.bounds.x1 end
    if Camera.x > max_x then Camera.x = max_x end
    if Camera.y < Camera.bounds.y1 then Camera.y = Camera.bounds.y1 end
    if Camera.y > max_y then Camera.y = max_y end
    
    -- Update shake
    if Camera.shake_duration > 0 then
        Camera.shake_duration = Camera.shake_duration - dt
        if Camera.shake_duration < 0 then
            Camera.shake_duration = 0
            Camera.shake_amount = 0
        end
    end
end

function Camera.attach()
    local ox = math.floor(Camera.x)
    local oy = math.floor(Camera.y)
    
    if Camera.shake_duration > 0 and Camera.shake_amount > 0 then
        -- Add random shake offset
        ox = ox + math.random(-Camera.shake_amount, Camera.shake_amount)
        oy = oy + math.random(-Camera.shake_amount, Camera.shake_amount)
    end
    
    -- There's no built-in camera function in basic gfx besides drawing with offsets.
    -- However, we can export these values and apply them in drawing loops, OR 
    -- if Usagi has a set_camera/translate function, we'd use it here.
    -- Since it's a fixed pipeline, we typically pass ox, oy to all draw calls, or store globally.
    Camera.ox = ox
    Camera.oy = oy
end

function Camera.detach()
    Camera.ox = 0
    Camera.oy = 0
end

-- Utility for drawing relative to camera
function Camera.world_to_screen(wx, wy)
    return wx - (Camera.ox or 0), wy - (Camera.oy or 0)
end

return Camera
