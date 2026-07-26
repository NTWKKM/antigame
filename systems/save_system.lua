-- systems/save_system.lua
local SaveSystem = {}

function SaveSystem.save()
    local data = {
        GameState = GameState,
        Party = Party,
        Inventory = (package.loaded["systems.inventory"] or _G.Inventory),
        QuestTracker = QuestTracker,
        UXIndex = UXIndex,
        timestamp = os.time()
    }
    usagi.save(data)
end

function SaveSystem.load()
    local data = usagi.load()
    if data then
        if data.GameState then GameState = data.GameState end
        if data.Party then Party = data.Party end
        if data.Inventory then 
            local Inventory = package.loaded["systems.inventory"] or _G.Inventory
            if Inventory then
                for k,v in pairs(data.Inventory) do Inventory[k] = v end
            end
        end
        if data.QuestTracker then QuestTracker = data.QuestTracker end
        if data.UXIndex then UXIndex = data.UXIndex end
        return data
    end
    return nil
end

return SaveSystem
