-- systems/resolution_decay.lua
local ResolutionDecay = {}

-- Resolution represents the structural integrity of reality
-- High RES (100) = Normal, safe
-- Low RES (0) = Reality breakdown, dangerous anomalies, game over

function ResolutionDecay.init()
    if not GameState.res then GameState.res = 100 end
end

function ResolutionDecay.modify(amount)
    GameState.res = GameState.res + amount
    if GameState.res > 100 then GameState.res = 100 end
    if GameState.res < 0 then GameState.res = 0 end
    
    -- Visual impact handled in draw loop via shader parameters
end

function ResolutionDecay.update(dt)
    -- In certain areas (low RES zones), RES might decay over time
    -- We can check GameState.current_zone_decay_rate
end

function ResolutionDecay.get_shader_intensity()
    -- Map RES to shader distortion intensity
    -- 100 -> 0 distortion
    -- 0 -> 1.0 distortion
    return 1.0 - (GameState.res / 100.0)
end

return ResolutionDecay
