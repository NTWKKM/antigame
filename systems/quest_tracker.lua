local quest_tracker = {
    flags = {},
    active_quests = {}
}

function quest_tracker.set_flag(id, val)
    quest_tracker.flags[id] = val
end

function quest_tracker.get_flag(id)
    return quest_tracker.flags[id]
end

function quest_tracker.start_quest(id)
    if not quest_tracker.active_quests[id] then
        quest_tracker.active_quests[id] = { status = "active", objective = 1 }
    end
end

function quest_tracker.advance_quest(id)
    if quest_tracker.active_quests[id] then
        quest_tracker.active_quests[id].objective = quest_tracker.active_quests[id].objective + 1
    end
end

function quest_tracker.complete_quest(id)
    if quest_tracker.active_quests[id] then
        quest_tracker.active_quests[id].status = "completed"
    end
end

return quest_tracker
