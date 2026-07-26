-- battle/sync_tech.lua
local SyncTech = {
    combos = {}
}

-- Chrono Trigger style Double/Triple Techs
-- If two characters are "ready" in ATB, they can combine specific skills

function SyncTech.init()
    SyncTech.combos = {
        archive_breach = {
            id = "archive_breach",
            name = "Archive Breach",
            req1 = "Elias",
            req2 = "Vesper",
            damage_mult = 3.0,
            target = "single",
            cost = 0 
        },
        lunar_flare = {
            id = "lunar_flare",
            name = "Lunar Flare",
            req1 = "Lyra",
            req2 = "Vesper",
            damage_mult = 2.5,
            target = "all",
            cost = 0 
        }
    }
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
