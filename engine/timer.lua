local timer = {
    timers = {},
    _id_counter = 0
}

function timer.after(duration, callback)
    timer._id_counter = timer._id_counter + 1
    table.insert(timer.timers, {
        id = timer._id_counter,
        duration = duration,
        elapsed = 0,
        callback = callback,
        recurring = false
    })
    return timer._id_counter
end

function timer.every(interval, callback)
    timer._id_counter = timer._id_counter + 1
    table.insert(timer.timers, {
        id = timer._id_counter,
        duration = interval,
        elapsed = 0,
        callback = callback,
        recurring = true
    })
    return timer._id_counter
end

function timer.cancel(id)
    for i = #timer.timers, 1, -1 do
        if timer.timers[i].id == id then
            table.remove(timer.timers, i)
            return true
        end
    end
    return false
end

function timer.update(dt)
    for i = #timer.timers, 1, -1 do
        local t = timer.timers[i]
        t.elapsed = t.elapsed + dt
        if t.elapsed >= t.duration then
            t.callback()
            if t.recurring then
                t.elapsed = t.elapsed - t.duration
            else
                table.remove(timer.timers, i)
            end
        end
    end
end

return timer
