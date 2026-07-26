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

function transition.draw()
    if not transition.active then return end
    
    if transition.mode == "fade_out" then
        gfx.rect_fill(0, 0, 320, 180, 0, transition.progress)
    elseif transition.mode == "fade_in" then
        gfx.rect_fill(0, 0, 320, 180, 0, 1.0 - transition.progress)
    end
end

return transition
