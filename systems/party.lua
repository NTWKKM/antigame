-- systems/party.lua
local Party = {
    members = {},
    active_party = {},
    max_active = 3
}

-- Character template
-- Elias (DPS/Sync), Vesper (Support/Tech), Lyra (Mage/AOE)

function Party.init()
    Party.members = {
        elias = {
            id = "elias",
            name = "Elias",
            hp = 100, max_hp = 100,
            atk = 15, def = 10, spd = 12,
            fragments = {}, -- Equipped Core Fragments
            skills = {"strike", "sync_slash"}
        },
        vesper = {
            id = "vesper",
            name = "Vesper",
            hp = 80, max_hp = 80,
            atk = 8, def = 12, spd = 15,
            fragments = {},
            skills = {"scan", "heal_drone"}
        },
        lyra = {
            id = "lyra",
            name = "Lyra",
            hp = 70, max_hp = 70,
            atk = 20, def = 8, spd = 10,
            fragments = {},
            skills = {"fireball", "ice_spike"}
        }
    }
    
    -- Load from GameState if exists
    if GameState and GameState.party then
        Party.active_party = GameState.party
    else
        Party.active_party = {"elias"}
    end
end

function Party.add_member(id)
    if not Party.members[id] then return false end
    for _, member_id in ipairs(Party.active_party) do
        if member_id == id then return true end -- Already in party
    end
    if #Party.active_party < Party.max_active then
        table.insert(Party.active_party, id)
        GameState.party = Party.active_party
        return true
    end
    return false
end

function Party.get_active_stats()
    local stats = {}
    for _, id in ipairs(Party.active_party) do
        table.insert(stats, Party.members[id])
    end
    return stats
end

return Party
