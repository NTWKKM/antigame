-- systems/save_manager.lua
local SaveManager = {
    current_slot = 1,
    max_slots = 4 -- 1 Autosave, 3 Manual
}

function SaveManager.save(slot)
    slot = slot or SaveManager.current_slot
    
    -- Ensure global GameState is updated with specific subsystem data if needed
    -- e.g. GameState.party is already linked, but if others aren't:
    -- GameState.res = ResolutionDecay.current_res
    
    -- Usagi's built in save function saves to a unified config file per game_id
    -- To support slots, we can wrap our state in a slot table
    local full_save = usagi.load() or {}
    full_save["slot_" .. slot] = GameState
    
    usagi.save(full_save)
    print("Saved to slot " .. slot)
end

function SaveManager.load(slot)
    local full_save = usagi.load()
    if full_save and full_save["slot_" .. slot] then
        GameState = full_save["slot_" .. slot]
        SaveManager.current_slot = slot
        print("Loaded from slot " .. slot)
        return true
    end
    print("No save data in slot " .. slot)
    return false
end

function SaveManager.autosave()
    SaveManager.save(0) -- Slot 0 is autosave
end

return SaveManager
