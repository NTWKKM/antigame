local timer = {
    timers = {}
}

function timer.after(duration, callback)
    table.insert(timer.timers, {
        duration = duration,
        elapsed = 0,
        callback = callback
    })
end

function timer.update(dt)
    for i = #timer.timers, 1, -1 do
        local t = timer.timers[i]
        t.elapsed = t.elapsed + dt
        if t.elapsed >= t.duration then
            t.callback()
            table.remove(timer.timers, i)
        end
    end
end

return timer
