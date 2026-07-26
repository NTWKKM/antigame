local skill_executor = {}

local cached_skills = nil

local function load_skills()
    if cached_skills then return cached_skills end
    cached_skills = {}
    
    local files = {
        "data/skills/elias_skills.json",
        "data/skills/vesper_skills.json",
        "data/skills/sync_techs.json"
    }
    
    for _, f in ipairs(files) do
        local data = usagi.read_json(f)
        if data and data.skills then
            for k, v in pairs(data.skills) do
                cached_skills[k] = v
            end
        end
    end
    
    return cached_skills
end

function skill_executor.execute(skill_id, user, target)
    local db = load_skills()
    local skill_data = db[skill_id]
    
    if not skill_data then
        skill_data = {
            name = "Strike",
            power = 1.0,
            type = "physical"
        }
    end
    
    local result = {
        name = skill_data.name,
        type = skill_data.type,
        damage = 0,
        hit = true
    }
    
    if skill_data.type == "support" then
        if skill_data.heal_power then
            result.damage = -math.max(1, user.stats.mag * skill_data.heal_power)
            if target.hp then
                target.hp = math.min(target.max_hp or target.hp, target.hp - result.damage)
            end
        end
    else
        local dmg = 0
        if skill_data.type == "physical" then
            dmg = math.max(1, (user.stats.atk * skill_data.power) - ((target.stats.def or 0) / 2))
        elseif skill_data.type == "tech" then
            dmg = math.max(1, (user.stats.mag * skill_data.power) - ((target.stats.mdef or 0) / 2))
        end
        
        result.damage = dmg
        if target.hp then
            target.hp = math.max(0, target.hp - dmg)
        end
    end
    
    return result
end

return skill_executor
