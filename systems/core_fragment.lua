-- systems/core_fragment.lua
local CoreFragment = {
    fragments = {}
}

-- FF6 Magicite/Relic hybrid
-- Fragments can be equipped to party members to teach skills and give stat boosts

function CoreFragment.init()
    CoreFragment.fragments = {
        chrono_shard = {
            id = "chrono_shard",
            name = "Chrono Shard",
            desc = "A shard of distorted time. Grants Haste.",
            stat_boosts = { spd = 5 },
            skills = {"haste", "slow"}
        },
        aegis_core = {
            id = "aegis_core",
            name = "Aegis Core",
            desc = "Provides defensive tactical algorithms.",
            stat_boosts = { def = 10, max_hp = 20 },
            skills = {"shield_wall"}
        }
    }
end

function CoreFragment.equip(member, fragment_id)
    if not CoreFragment.fragments[fragment_id] then return false end
    if #member.fragments >= 2 then return false end -- Max 2 per character
    
    table.insert(member.fragments, fragment_id)
    
    -- Apply stat boosts (would be applied during stat calculation)
    return true
end

function CoreFragment.get_equipped_skills(member)
    local skills = {}
    for _, frag_id in ipairs(member.fragments) do
        local frag = CoreFragment.fragments[frag_id]
        if frag and frag.skills then
            for _, skill in ipairs(frag.skills) do
                table.insert(skills, skill)
            end
        end
    end
    return skills
end

return CoreFragment
