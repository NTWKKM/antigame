-- battle/resolution_gauge.lua
local ResolutionGauge = {
    value = 0,
    min = -50,
    max = 50,
    sweet_spot_min = 10,
    sweet_spot_max = 30
}

-- Chained Echoes style Overdrive gauge
-- Moves based on actions used. 
-- Normal (0-10) -> Normal damage/cost
-- Sweet Spot (10-30) -> High damage, low cost (Resonance)
-- Overheat (30-50) -> Takes more damage, high cost (Instability)

function ResolutionGauge.init()
    ResolutionGauge.value = 0
end

function ResolutionGauge.apply_action(skill_impact)
    ResolutionGauge.value = ResolutionGauge.value + skill_impact
    if ResolutionGauge.value > ResolutionGauge.max then ResolutionGauge.value = ResolutionGauge.max end
    if ResolutionGauge.value < ResolutionGauge.min then ResolutionGauge.value = ResolutionGauge.min end
end

function ResolutionGauge.get_state()
    if ResolutionGauge.value >= ResolutionGauge.sweet_spot_min and ResolutionGauge.value <= ResolutionGauge.sweet_spot_max then
        return "RESONANCE"
    elseif ResolutionGauge.value > ResolutionGauge.sweet_spot_max then
        return "INSTABILITY"
    else
        return "NORMAL"
    end
end

function ResolutionGauge.get_modifiers()
    local state = ResolutionGauge.get_state()
    if state == "RESONANCE" then
        return { dmg_out = 1.25, dmg_in = 0.75, cost = 0.5 }
    elseif state == "INSTABILITY" then
        return { dmg_out = 0.75, dmg_in = 1.5, cost = 1.5 }
    else
        return { dmg_out = 1.0, dmg_in = 1.0, cost = 1.0 }
    end
end

return ResolutionGauge
