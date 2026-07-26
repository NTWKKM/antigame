-- systems/quest_tracker.lua
local QuestTracker = {
    chapter = 1,
    phase = 1,
    resolution_state = "Pristine", -- Pristine, Degrading, Bit Rot, Dead Zone
    current_quest = "The Taste of Golden Pixels",
    quest_step = 1,
    flags = {}
}

local CHAPTER_NAMES = {
    -- Act 1: The Sector 7 Job
    [1] = "Chapter 1: The Sector 7 Bounty",
    [2] = "Chapter 2: Slums and Scavengers",
    [3] = "Chapter 3: Substation 07",
    [4] = "Chapter 4: The Golden Data Cube",
    [5] = "Chapter 5: Archive Alert",
    
    -- Act 2: The Fragment Market & Sunken Archives
    [6] = "Chapter 6: Escape to the Mid-Sectors",
    [7] = "Chapter 7: The Fragment Market",
    [8] = "Chapter 8: Decrypting the Truth",
    [9] = "Chapter 9: The Sunken Archives",
    [10] = "Chapter 10: The Memory Eater",
    
    -- Act 3: Defense of the Mid-Sector
    [11] = "Chapter 11: The Sweeper Raid",
    [12] = "Chapter 12: Rallying The Eroded",
    [13] = "Chapter 13: Syndicate Complex",
    [14] = "Chapter 14: The Assembly Line",
    [15] = "Chapter 15: Stand Your Ground",
    
    -- Act 4: Sabotaging the Node
    [16] = "Chapter 16: The Desperate Plan",
    [17] = "Chapter 17: Edge of the Dead Zone",
    [18] = "Chapter 18: Infiltrating the Node",
    [19] = "Chapter 19: The Node Custodian",
    [20] = "Chapter 20: Disconnected"
}

function QuestTracker.init()
    if GameState and GameState.quest then
        QuestTracker.chapter = GameState.quest.chapter or 1
        QuestTracker.phase = GameState.quest.phase or 1
        QuestTracker.resolution_state = GameState.quest.resolution_state or "Pristine"
        QuestTracker.current_quest = CHAPTER_NAMES[QuestTracker.chapter] or CHAPTER_NAMES[1]
        QuestTracker.flags = GameState.quest.flags or {}
    else
        QuestTracker.chapter = 1
        QuestTracker.phase = 1
        QuestTracker.resolution_state = "Pristine"
        QuestTracker.current_quest = CHAPTER_NAMES[1]
        QuestTracker.flags = {}
    end
end

function QuestTracker.advance_chapter()
    if QuestTracker.chapter < 20 then
        QuestTracker.chapter = QuestTracker.chapter + 1
        QuestTracker.current_quest = CHAPTER_NAMES[QuestTracker.chapter]
        
        -- Update Phase and Resolution State based on chapter bounds
        if QuestTracker.chapter <= 5 then
            QuestTracker.phase = 1
            QuestTracker.resolution_state = "Pristine"
        elseif QuestTracker.chapter <= 10 then
            QuestTracker.phase = 2
            QuestTracker.resolution_state = "Degrading"
        elseif QuestTracker.chapter <= 15 then
            QuestTracker.phase = 3
            QuestTracker.resolution_state = "Bit Rot"
        else
            QuestTracker.phase = 4
            QuestTracker.resolution_state = "Dead Zone"
        end
        
        -- Sync to GameState
        if GameState then
            GameState.quest = {
                chapter = QuestTracker.chapter,
                phase = QuestTracker.phase,
                resolution_state = QuestTracker.resolution_state,
                flags = QuestTracker.flags
            }
        end
        print("Advanced to " .. QuestTracker.current_quest)
    end
end

function QuestTracker.set_flag(flag_name, value)
    QuestTracker.flags[flag_name] = value or true
    if GameState and GameState.quest then
        GameState.quest.flags = QuestTracker.flags
    end
end

function QuestTracker.has_flag(flag_name)
    return QuestTracker.flags[flag_name] == true
end

function QuestTracker.get_shader_intensity()
    if QuestTracker.resolution_state == "Pristine" then
        return 0.0
    elseif QuestTracker.resolution_state == "Degrading" then
        return 0.25
    elseif QuestTracker.resolution_state == "Bit Rot" then
        return 0.6
    else
        return 0.95 -- Dead Zone / Null Coordinate
    end
end

return QuestTracker
