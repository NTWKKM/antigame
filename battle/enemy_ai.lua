local enemy_ai = {}

function enemy_ai.decide_action(enemy, party)
    local target = party[math.random(#party)]
    local hp_pct = enemy.hp / (enemy.max_hp or 1)
    
    -- Lowest HP targeting if enemy hp > 50%
    if hp_pct > 0.5 then
        local lowest_hp = math.huge
        for _, p in ipairs(party) do
            if p.hp > 0 and p.hp < lowest_hp then
                lowest_hp = p.hp
                target = p
            end
        end
    end
    
    local is_boss = enemy.boss or (enemy.max_hp and enemy.max_hp > 200)
    
    if is_boss then
        if hp_pct > 0.5 then
            -- Phase 1: Alternate
            enemy._ai_turn = (enemy._ai_turn or 0) + 1
            if enemy._ai_turn % 2 == 0 and enemy.skills and #enemy.skills > 0 then
                return enemy.skills[math.random(#enemy.skills)], target
            else
                return "strike", target
            end
        else
            -- Phase 2: Strongest skill / aggressive
            if enemy.skills and #enemy.skills > 0 then
                -- Simplification: Just use the last skill as "strongest" for now
                return enemy.skills[#enemy.skills], target
            else
                return "strike", target
            end
        end
    end
    
    -- Defensive mode
    if hp_pct < 0.3 and enemy.skills then
        for _, skill in ipairs(enemy.skills) do
            -- Assuming skill naming convention or simple check, for now fallback to heal if present
            if type(skill) == "string" and skill:match("heal") then
                return skill, enemy
            end
        end
    end
    
    if not enemy.skills or #enemy.skills == 0 then
        return "strike", target
    end
    
    local skill = enemy.skills[math.random(#enemy.skills)]
    return skill, target
end

return enemy_ai
