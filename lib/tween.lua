-- lib/tween.lua — Managed Tween System for Primordium City
-- Provides lifecycle-managed property animation with easing functions

local Tween = {
    active_tweens = {},
    next_id = 1
}

--------------------------------------------------------------------
-- EASING FUNCTIONS
-- All take (t) where t is normalized 0..1, return 0..1
--------------------------------------------------------------------

function Tween.linear(t)
    return t
end

function Tween.easeInQuad(t)
    return t * t
end

function Tween.easeOutQuad(t)
    return t * (2 - t)
end

function Tween.easeInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

function Tween.easeOutCubic(t)
    t = t - 1
    return t * t * t + 1
end

function Tween.easeInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        t = t - 1
        return 1 + 4 * t * t * t
    end
end

function Tween.easeOutBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
end

function Tween.easeOutElastic(t)
    if t == 0 or t == 1 then return t end
    local c4 = (2 * math.pi) / 3
    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

function Tween.easeOutBounce(t)
    local n1 = 7.5625
    local d1 = 2.75
    if t < 1 / d1 then
        return n1 * t * t
    elseif t < 2 / d1 then
        t = t - 1.5 / d1
        return n1 * t * t + 0.75
    elseif t < 2.5 / d1 then
        t = t - 2.25 / d1
        return n1 * t * t + 0.9375
    else
        t = t - 2.625 / d1
        return n1 * t * t + 0.984375
    end
end

function Tween.easeInExpo(t)
    if t == 0 then return 0 end
    return math.pow(2, 10 * (t - 1))
end

function Tween.easeOutExpo(t)
    if t == 1 then return 1 end
    return 1 - math.pow(2, -10 * t)
end

--------------------------------------------------------------------
-- TWEEN MANAGEMENT
--------------------------------------------------------------------

--- Create a tween that animates properties on `subject` toward `target` values.
--- @param subject table  The object whose properties will be animated
--- @param duration number  Duration in seconds
--- @param target table  Target property values {x=100, y=50, alpha=0}
--- @param easing function  Easing function (default: easeOutQuad)
--- @param callback function  Called when tween completes (optional)
--- @return number  Tween handle ID for cancellation
function Tween.to(subject, duration, target, easing, callback)
    local id = Tween.next_id
    Tween.next_id = Tween.next_id + 1
    
    -- Capture starting values
    local start_values = {}
    for key, _ in pairs(target) do
        start_values[key] = subject[key] or 0
    end
    
    local tween_obj = {
        id = id,
        subject = subject,
        target = target,
        start_values = start_values,
        duration = duration,
        elapsed = 0,
        easing = easing or Tween.easeOutQuad,
        callback = callback,
        finished = false
    }
    
    table.insert(Tween.active_tweens, tween_obj)
    return id
end

--- Create a tween that starts from `from` values and goes to current values.
--- Useful for "punch" effects (scale up then back to normal).
function Tween.from(subject, duration, from_values, easing, callback)
    -- Store current values as targets
    local target = {}
    for key, _ in pairs(from_values) do
        target[key] = subject[key] or 0
        -- Set the subject to the "from" values immediately
        subject[key] = from_values[key]
    end
    return Tween.to(subject, duration, target, easing, callback)
end

--- Cancel a specific tween by handle ID
function Tween.cancel(id)
    for i = #Tween.active_tweens, 1, -1 do
        if Tween.active_tweens[i].id == id then
            table.remove(Tween.active_tweens, i)
            return true
        end
    end
    return false
end

--- Cancel all tweens on a specific subject
function Tween.cancel_target(subject)
    for i = #Tween.active_tweens, 1, -1 do
        if Tween.active_tweens[i].subject == subject then
            table.remove(Tween.active_tweens, i)
        end
    end
end

--- Cancel all active tweens
function Tween.cancel_all()
    Tween.active_tweens = {}
end

--- Check if any tweens are active on a subject
function Tween.is_tweening(subject)
    for _, tw in ipairs(Tween.active_tweens) do
        if tw.subject == subject then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------
-- SEQUENCING (chain tweens)
--------------------------------------------------------------------

--- Chain multiple tweens to run in sequence on the same subject.
--- @param subject table
--- @param steps table  Array of {duration, target, easing}
--- @param callback function  Called when entire chain completes
function Tween.sequence(subject, steps, callback)
    local function run_step(index)
        if index > #steps then
            if callback then callback() end
            return
        end
        local step = steps[index]
        Tween.to(subject, step.duration or step[1], step.target or step[2], step.easing or step[3], function()
            run_step(index + 1)
        end)
    end
    run_step(1)
end

--------------------------------------------------------------------
-- UPDATE (call once per frame from main.lua)
--------------------------------------------------------------------

function Tween.update(dt)
    for i = #Tween.active_tweens, 1, -1 do
        local tw = Tween.active_tweens[i]
        tw.elapsed = tw.elapsed + dt
        
        local raw_t = tw.elapsed / tw.duration
        if raw_t >= 1.0 then raw_t = 1.0 end
        
        -- Apply easing
        local eased_t = tw.easing(raw_t)
        
        -- Interpolate all target properties
        for key, target_val in pairs(tw.target) do
            local start_val = tw.start_values[key]
            tw.subject[key] = start_val + (target_val - start_val) * eased_t
        end
        
        -- Check completion
        if raw_t >= 1.0 then
            -- Snap to exact target values
            for key, target_val in pairs(tw.target) do
                tw.subject[key] = target_val
            end
            table.remove(Tween.active_tweens, i)
            if tw.callback then
                tw.callback()
            end
        end
    end
end

return Tween
