-- systems/ux_index.lua
local UXIndex = {
    anomaly_timer = 0,
    anomaly_message = nil
}

-- Unpredictability Index (UXI)
-- Represents chaotic actions. Using powerful skills or breaking rules increases UX.
-- High UX triggers anomalies, tougher enemies, or narrative changes.

function UXIndex.init()
    if not GameState then GameState = {} end
    if not GameState.ux then GameState.ux = 0 end
    UXIndex.anomaly_timer = 0
    UXIndex.anomaly_message = nil
end

function UXIndex.add(amount)
    if not GameState then return end
    GameState.ux = (GameState.ux or 0) + amount
    if GameState.ux > 100 then GameState.ux = 100 end
    
    if GameState.ux >= 100 then
        UXIndex.trigger_anomaly()
    end
end

function UXIndex.reduce(amount)
    if not GameState then return end
    GameState.ux = (GameState.ux or 0) - amount
    if GameState.ux < 0 then GameState.ux = 0 end
end

function UXIndex.update(dt)
    if UXIndex.anomaly_timer > 0 then
        UXIndex.anomaly_timer = UXIndex.anomaly_timer - dt
        if UXIndex.anomaly_timer <= 0 then
            UXIndex.anomaly_timer = 0
            UXIndex.anomaly_message = nil
        end
    end
end

function UXIndex.trigger_anomaly()
    print("WARNING: UX Index critical! Anomaly triggered.")
    
    -- Reduce accumulated UX to reset trigger state
    UXIndex.reduce(50)
    
    -- Apply screen shake
    if Camera and Camera.shake then
        Camera.shake(5, 0.6)
    end
    
    -- Play glitch sound effect
    if sfx and sfx.play then
        sfx.play("glitch")
    end
    
    -- Apply RES penalty linking UX chaos to reality decay
    local ResolutionDecay = require("systems.resolution_decay")
    ResolutionDecay.modify(-10)
    
    -- Set HUD message banner
    UXIndex.anomaly_timer = 3.0
    UXIndex.anomaly_message = "ANOMALY DETECTED: REALITY DISTORTED!"
end

return UXIndex

