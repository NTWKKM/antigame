-- battle/resolution_gauge.lua
local ResolutionGauge = {
    value = 0,
    min = 0,
    max = 100,
    sweet_spot_min = 25,
    sweet_spot_max = 70
}

function ResolutionGauge.init()
    ResolutionGauge.value = 0
    local cfg = usagi.read_json("config/balance.json")
    if cfg and cfg.balance then
        ResolutionGauge.min = cfg.balance.gauge_min or 0
        ResolutionGauge.max = cfg.balance.gauge_max or 100
        ResolutionGauge.sweet_spot_min = cfg.balance.overdrive_green_min or 25
        ResolutionGauge.sweet_spot_max = cfg.balance.overdrive_green_max or 70
    end
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
