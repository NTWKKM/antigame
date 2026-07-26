local enemy_ai = {}

function enemy_ai.decide_action(enemy, party)
    -- Simple random AI for Arc 1
    if not enemy.skills or #enemy.skills == 0 then
        return "strike", party[math.random(#party)]
    end
    
    local skill = enemy.skills[math.random(#enemy.skills)]
    local target = party[math.random(#party)]
    
    return skill, target
end

return enemy_ai
