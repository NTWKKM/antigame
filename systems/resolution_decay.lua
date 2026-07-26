-- systems/resolution_decay.lua
local ResolutionDecay = {}

-- Resolution represents the structural integrity of reality
-- High RES (100) = Normal, safe
-- Low RES (0) = Reality breakdown, dangerous anomalies, game over

function ResolutionDecay.init()
    if not GameState then GameState = {} end
    if not GameState.res then GameState.res = 100 end
    if not GameState.current_zone_decay_rate then GameState.current_zone_decay_rate = 0.0 end
end

function ResolutionDecay.modify(amount)
    if not GameState or not GameState.res then return end
    GameState.res = GameState.res + amount
    if GameState.res > 100 then GameState.res = 100 end
    if GameState.res < 0 then GameState.res = 0 end
end

function ResolutionDecay.update(dt)
    if not GameState or not GameState.res then return end
    
    -- Passive zone decay if specified
    local rate = GameState.current_zone_decay_rate or 0.0
    if rate > 0 then
        ResolutionDecay.modify(-rate * dt)
    end
end

function ResolutionDecay.get_resolution_state()
    local res = (GameState and GameState.res) or 100
    if res >= 75 then
        return "Pristine"
    elseif res >= 50 then
        return "Degrading"
    elseif res >= 25 then
        return "Bit Rot"
    else
        return "Dead Zone"
    end
end

function ResolutionDecay.get_shader_intensity()
    local res = (GameState and GameState.res) or 100
    -- Map RES to shader distortion intensity: 100 -> 0.0, 0 -> 1.0
    local intensity = 1.0 - (res / 100.0)
    if intensity < 0.0 then intensity = 0.0 end
    if intensity > 1.0 then intensity = 1.0 end
    return intensity
end

return ResolutionDecay

