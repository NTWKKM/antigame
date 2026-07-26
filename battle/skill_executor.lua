local skill_executor = {}

function skill_executor.execute(skill_id, user, target)
    -- Find skill data
    local skill_data = nil
    -- Simplification: assume we just load elias/vesper/sync for now
    local elias_skills = usagi.read_json("data/skills/elias_skills.json").skills
    local vesper_skills = usagi.read_json("data/skills/vesper_skills.json").skills
    
    skill_data = elias_skills[skill_id] or vesper_skills[skill_id]
    
    if not skill_data then
        -- Fallback physical strike
        skill_data = {
            name = "Strike",
            power = 1.0,
            type = "physical"
        }
    end
    
    -- Calculate damage
    local dmg = 0
    if skill_data.type == "physical" then
        dmg = math.max(1, (user.stats.atk * skill_data.power) - (target.stats.def / 2))
    elseif skill_data.type == "tech" then
        dmg = math.max(1, (user.stats.mag * skill_data.power) - (target.stats.mdef / 2))
    end
    
    -- Apply damage
    if target.hp then
        target.hp = math.max(0, target.hp - dmg)
    end
    
    return dmg
end

return skill_executor
