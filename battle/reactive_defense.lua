-- battle/reactive_defense.lua
local ReactiveDefense = {
    active = false,
    timer = 0,
    window = 1.0, -- 1 second to react
    target_combatant = nil,
    attack_name = "",
    success_level = "miss", -- perfect, good, miss
    resolved = false,
    start_radius = 40,
    target_radius = 10,
    current_radius = 40
}

-- Clair Obscur 33 style: When enemies attack, player has a window to parry/defend
function ReactiveDefense.start(combatant, attack_name, window_override)
    ReactiveDefense.active = true
    ReactiveDefense.timer = window_override or ReactiveDefense.window
    ReactiveDefense.window = window_override or ReactiveDefense.window
    ReactiveDefense.target_combatant = combatant
    ReactiveDefense.attack_name = attack_name
    ReactiveDefense.success_level = "miss"
    ReactiveDefense.resolved = false
    ReactiveDefense.current_radius = ReactiveDefense.start_radius
end

function ReactiveDefense.update(dt)
    if not ReactiveDefense.active then return end
    
    if ReactiveDefense.timer > 0 then
        ReactiveDefense.timer = ReactiveDefense.timer - dt
        
        -- Calculate current shrinking radius
        local progress = 1.0 - (ReactiveDefense.timer / ReactiveDefense.window)
        ReactiveDefense.current_radius = ReactiveDefense.start_radius - (ReactiveDefense.start_radius * progress)
        
        if input.pressed(input.BTN1) and not ReactiveDefense.resolved then
            ReactiveDefense.resolved = true
            
            -- Evaluate timing based on radius
            -- Perfect: wide window (r between 7 and 13, target is 10)
            -- Good: wider window (r between 4 and 16)
            local diff = math.abs(ReactiveDefense.current_radius - ReactiveDefense.target_radius)
            if diff <= 3.0 then
                ReactiveDefense.success_level = "perfect"
                sfx.play("jump") -- ping sound for perfect
            elseif diff <= 6.0 then
                ReactiveDefense.success_level = "good"
                sfx.play("hit") -- duller sound for good
            else
                ReactiveDefense.success_level = "miss"
                sfx.play("hurt")
            end
        end
        
        if ReactiveDefense.timer <= 0 and not ReactiveDefense.resolved then
            -- Failed to react
            ReactiveDefense.success_level = "miss"
            ReactiveDefense.resolved = true
        end
    else
        -- Small delay after resolve before hiding
        ReactiveDefense.active = false
    end
end

function ReactiveDefense.get_mitigation()
    if ReactiveDefense.success_level == "perfect" then
        return 0.0 -- 0% damage taken (negated!)
    elseif ReactiveDefense.success_level == "good" then
        return 0.5 -- 50% damage reduction
    end
    return 1.0 -- Full damage
end

function ReactiveDefense.draw()
    if not ReactiveDefense.active then return end
    if not ReactiveDefense.target_combatant then return end
    
    local tx = ReactiveDefense.target_combatant.x + 8 -- center of 16x16 sprite
    local ty = ReactiveDefense.target_combatant.y + 8
    
    -- Draw static target ring (blue)
    gfx.circ(tx, ty, ReactiveDefense.target_radius, gfx.COLOR_BLUE)
    
    if not ReactiveDefense.resolved then
        -- Draw shrinking outer ring (white)
        gfx.circ(tx, ty, math.max(1, math.floor(ReactiveDefense.current_radius)), gfx.COLOR_WHITE)
    else
        -- Draw feedback word
        if ReactiveDefense.success_level == "perfect" then
            gfx.text("PERFECT", tx - 15, ty - 20, gfx.COLOR_GREEN)
        elseif ReactiveDefense.success_level == "good" then
            gfx.text("GOOD", tx - 8, ty - 20, gfx.COLOR_YELLOW)
        else
            gfx.text("MISS", tx - 8, ty - 20, gfx.COLOR_RED)
        end
    end
    
    -- Draw Attack Name
    gfx.text(ReactiveDefense.attack_name, tx - 10, ty + 15, gfx.COLOR_WHITE)
end

return ReactiveDefense
