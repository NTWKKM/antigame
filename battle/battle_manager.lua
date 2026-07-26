local battle_manager = {
    state = "init",
    enemies = {},
    party = {},
    current_turn = nil
}

function battle_manager.init(encounter_id)
    battle_manager.state = "init"
    local data = usagi.read_json("data/encounters/arc1_encounters.json")
    local encounter = data.encounters[encounter_id]
    
    battle_manager.enemies = {}
    if encounter and encounter.enemies then
        local enemy_data = usagi.read_json("data/enemies/arc1_enemies.json").enemies
        for _, eid in ipairs(encounter.enemies) do
            local ed = enemy_data[eid]
            if ed then
                table.insert(battle_manager.enemies, {
                    id = eid,
                    name = ed.name,
                    hp = ed.stats.hp,
                    max_hp = ed.stats.max_hp,
                    stats = ed.stats,
                    skills = ed.skills
                })
            end
        end
    end
end

function battle_manager.update(dt)
    -- Battle loop handled by state machine and timeline
end

return battle_manager
