local transition = {
    active = false,
    mode = "fade_out",
    progress = 0,
    speed = 2.0,
    callback = nil
}

function transition.start(mode, speed, callback)
    transition.active = true
    transition.mode = mode
    transition.speed = speed or 2.0
    transition.progress = 0
    transition.callback = callback
end

function transition.update(dt)
    if not transition.active then return end
    transition.progress = transition.progress + dt * transition.speed
    if transition.progress >= 1.0 then
        transition.progress = 1.0
        transition.active = false
        if transition.callback then
            local cb = transition.callback
            transition.callback = nil
            cb()
        end
    end
end

local function easeInOutQuad(x)
    return x < 0.5 and 2 * x * x or 1 - ((-2 * x + 2) ^ 2) / 2
end

function transition.draw()
    if not transition.active then return end
    
    local w = usagi.GAME_W
    local h = usagi.GAME_H
    local p = easeInOutQuad(transition.progress)
    
    if transition.mode == "fade_out" then
        gfx.rect_fill(0, 0, w, h, gfx.COLOR_BLACK, p)
    elseif transition.mode == "fade_in" then
        gfx.rect_fill(0, 0, w, h, gfx.COLOR_BLACK, 1.0 - p)
    elseif transition.mode == "glitch_out" or transition.mode == "glitch_in" then
        local glitch_p = transition.mode == "glitch_out" and p or (1.0 - p)
        local slices = 12
        local slice_h = math.ceil(h / slices)
        for i = 0, slices - 1 do
            local y = i * slice_h
            if math.random() < glitch_p * 1.5 then
                local offset = (math.random() - 0.5) * 60 * glitch_p
                gfx.rect_fill(offset, y, w, slice_h, gfx.COLOR_RED, glitch_p * 0.7)
                gfx.rect_fill(-offset, y, w, slice_h, gfx.COLOR_BLUE, glitch_p * 0.7)
                gfx.rect_fill(0, y, w, slice_h, gfx.COLOR_BLACK, glitch_p * 0.8)
            end
        end
        gfx.rect_fill(0, 0, w, h, gfx.COLOR_BLACK, glitch_p * glitch_p)
    elseif transition.mode == "iris_out" or transition.mode == "iris_in" then
        local iris_p = transition.mode == "iris_out" and p or (1.0 - p)
        local cx, cy = w / 2, h / 2
        local max_r = math.sqrt(cx*cx + cy*cy)
        local r = max_r * (1.0 - iris_p)
        
        for y = 0, h - 1 do
            local dy = y - cy
            if math.abs(dy) > r then
                gfx.line(0, y, w, y, gfx.COLOR_BLACK)
            else
                local dx = math.sqrt(r*r - dy*dy)
                gfx.line(0, y, cx - dx, y, gfx.COLOR_BLACK)
                gfx.line(cx + dx, y, w, y, gfx.COLOR_BLACK)
            end
        end
    end
end

return transition
