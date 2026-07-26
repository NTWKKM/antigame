-- systems/ux_index.lua
local UXIndex = {}

-- Unpredictability Index (UXI)
-- Represents chaotic actions. Using powerful skills or breaking rules increases UX.
-- High UX triggers anomalies, tougher enemies, or narrative changes.

function UXIndex.init()
    if not GameState.ux then GameState.ux = 0 end
end

function UXIndex.add(amount)
    GameState.ux = GameState.ux + amount
    if GameState.ux > 100 then GameState.ux = 100 end
    
    if GameState.ux >= 100 then
        UXIndex.trigger_anomaly()
    end
end

function UXIndex.reduce(amount)
    GameState.ux = GameState.ux - amount
    if GameState.ux < 0 then GameState.ux = 0 end
end

function UXIndex.trigger_anomaly()
    print("WARNING: UX Index critical! Anomaly triggered.")
    -- This might spawn a strong enemy or apply a debuff
    -- We can hook this into the State Machine
end

return UXIndex
