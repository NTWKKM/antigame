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
            hp = 100, max_hp = 100, tp = 20, max_tp = 20,
            atk = 15, def = 10, spd = 12,
            fragments = {}, -- Equipped Core Fragments
            skills = {"strike", "sync_slash"}
        },
        vesper = {
            id = "vesper",
            name = "Vesper",
            hp = 80, max_hp = 80, tp = 30, max_tp = 30,
            atk = 8, def = 12, spd = 15,
            fragments = {},
            skills = {"scan", "heal_drone"}
        },
        lyra = {
            id = "lyra",
            name = "Lyra",
            hp = 70, max_hp = 70, tp = 40, max_tp = 40,
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
    local CoreFragment = require("systems.core_fragment")
    
    for _, id in ipairs(Party.active_party) do
        local base = Party.members[id]
        
        -- Deep copy base to avoid permanent stat modification by buffs
        local c = {}
        for k, v in pairs(base) do
            if type(v) == "table" then
                c[k] = {}
                for i, j in pairs(v) do c[k][i] = j end
            else
                c[k] = v
            end
        end
        
        -- Apply fragment stats
        for _, frag_id in ipairs(base.fragments) do
            local frag = CoreFragment.fragments[frag_id]
            if frag and frag.stat_boosts then
                for stat_name, boost_amt in pairs(frag.stat_boosts) do
                    if c[stat_name] then
                        c[stat_name] = c[stat_name] + boost_amt
                    end
                end
            end
        end
        table.insert(stats, c)
    end
    return stats
end

function Party.update_member_status(id, hp, tp)
    if Party.members[id] then
        Party.members[id].hp = math.max(0, math.min(Party.members[id].max_hp, hp))
        Party.members[id].tp = math.max(0, math.min(Party.members[id].max_tp, tp))
    end
end

return Party
