-- systems/save_system.lua
local SaveSystem = {
    current_slot = 1,
    max_slots = 4
}

function SaveSystem.save(slot)
    slot = slot or SaveSystem.current_slot
    
    local data = {
        GameState = GameState,
        Party = Party,
        Inventory = (package.loaded["systems.inventory"] or _G.Inventory),
        QuestTracker = QuestTracker,
        UXIndex = UXIndex,
        timestamp = os.time()
    }
    
    local full_save = usagi.load() or {}
    full_save["slot_" .. slot] = data
    
    usagi.save(full_save)
    print("Saved to slot " .. slot)
end

function SaveSystem.load(slot)
    slot = slot or SaveSystem.current_slot
    local full_save = usagi.load()
    
    if full_save and full_save["slot_" .. slot] then
        local data = full_save["slot_" .. slot]
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
        
        SaveSystem.current_slot = slot
        print("Loaded from slot " .. slot)
        return data
    end
    print("No save data in slot " .. slot)
    return nil
end

function SaveSystem.autosave()
    SaveSystem.save(0)
end

return SaveSystem
