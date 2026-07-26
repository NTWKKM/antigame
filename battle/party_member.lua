local party_member = {}
party_member.__index = party_member

function party_member.new(id)
    local self = setmetatable({}, party_member)
    self.id = id
    
    local data = usagi.read_json("data/characters/" .. id .. ".json")
    if data then
        self.name = data.name
        self.hp = data.base_stats.hp
        self.max_hp = data.base_stats.max_hp
        self.tp = data.base_stats.tp
        self.max_tp = data.base_stats.max_tp
        self.stats = data.base_stats
        self.skills = data.skills
    else
        self.name = id
        self.hp, self.max_hp = 100, 100
        self.tp, self.max_tp = 50, 50
        self.stats = {atk=10, def=10, mag=10, mdef=10, spd=10, res=100}
        self.skills = {"strike"}
    end
    
    return self
end

function party_member:take_damage(amt)
    self.hp = math.max(0, self.hp - amt)
    if self.hp == 0 then
        -- Handle KO
    end
end

return party_member
