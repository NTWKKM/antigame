-- battle/sync_tech.lua
local SyncTech = {
    combos = {}
}

-- Chrono Trigger style Double/Triple Techs
-- If two characters are "ready" in ATB, they can combine specific skills

function SyncTech.init()
    SyncTech.combos = {}
    local data = usagi.read_json("data/skills/sync_techs.json")
    if data and data.sync_techs then
        for id, tech in pairs(data.sync_techs) do
            local req1 = tech.req_chars and tech.req_chars[1] or ""
            local req2 = tech.req_chars and tech.req_chars[2] or ""
            local combo = {
                id = tech.id,
                name = tech.name,
                req1 = req1:gsub("^%l", string.upper),
                req2 = req2:gsub("^%l", string.upper),
                damage_mult = tech.power or 1.0,
                target = tech.target == "all_enemies" and "all" or "single",
                cost = tech.req_tp or 0
            }
            SyncTech.combos[id] = combo
        end
    end
end

function SyncTech.get_available(ready_combatants)
    local available = {}
    
    -- Extract the names of the ready characters
    local ready_names = {}
    for _, c in ipairs(ready_combatants) do
        ready_names[c.name] = true
    end
    
    for id, combo in pairs(SyncTech.combos) do
        if ready_names[combo.req1] and ready_names[combo.req2] then
            table.insert(available, combo)
        end
    end
    
    return available
end

return SyncTech
