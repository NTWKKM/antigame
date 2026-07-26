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
            ReactiveDefense.result_scale = 2.0
            Tween.to(ReactiveDefense, 0.3, {result_scale = 1.0}, Tween.easeOutQuad)
            
            -- Evaluate timing based on radius
            -- Perfect: wide window (r between 7 and 13, target is 10)
            -- Good: wider window (r between 4 and 16)
            local diff = math.abs(ReactiveDefense.current_radius - ReactiveDefense.target_radius)
            if diff <= 3.0 then
                ReactiveDefense.success_level = "perfect"
                sfx.play("jump") -- ping sound for perfect
                FX.spawn_particles(ReactiveDefense.target_combatant.draw_x + 8, ReactiveDefense.target_combatant.draw_y + 8, 12, gfx.COLOR_GREEN, 50, 0.4)
                FX.screen_flash(gfx.COLOR_GREEN, 0.1)
                FX.request_hitstop(4)
            elseif diff <= 6.0 then
                ReactiveDefense.success_level = "good"
                sfx.play("hit") -- duller sound for good
                FX.request_hitstop(2)
            else
                ReactiveDefense.success_level = "miss"
                sfx.play("hurt")
            end
        end
        
        if ReactiveDefense.timer <= 0 and not ReactiveDefense.resolved then
            -- Failed to react
            ReactiveDefense.success_level = "miss"
            ReactiveDefense.resolved = true
            ReactiveDefense.result_scale = 2.0
            Tween.to(ReactiveDefense, 0.3, {result_scale = 1.0}, Tween.easeOutQuad)
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
            -- Draw shrinking outer ring
            local progress = 1.0 - (ReactiveDefense.timer / ReactiveDefense.window)
            local ring_color = gfx.COLOR_WHITE
            if progress > 0.66 then ring_color = gfx.COLOR_RED
            elseif progress > 0.33 then ring_color = gfx.COLOR_YELLOW end
            gfx.circ(tx, ty, math.max(1, math.floor(ReactiveDefense.current_radius)), ring_color)
    else
        -- Draw feedback word
        local scale = ReactiveDefense.result_scale or 1.0
        if ReactiveDefense.success_level == "perfect" then
            gfx.text_ex("PERFECT", tx - 15, ty - 20, scale, 0, gfx.COLOR_GREEN, 1.0)
        elseif ReactiveDefense.success_level == "good" then
            gfx.text_ex("GOOD", tx - 8, ty - 20, scale, 0, gfx.COLOR_YELLOW, 1.0)
        else
            gfx.text_ex("MISS", tx - 8, ty - 20, scale, 0, gfx.COLOR_RED, 1.0)
        end
    end
    
    -- Draw Attack Name
    gfx.text(ReactiveDefense.attack_name, tx - 10, ty + 15, gfx.COLOR_WHITE)
end

return ReactiveDefense
