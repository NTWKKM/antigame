local ChoiceMenu = require("ui.choice_menu")

local DialogueBox = {
    active = false,
    tree = nil,
    current_node = nil,
    text = "",
    display_text = "",
    speaker = "",
    char_index = 0,
    timer = 0,
    speed = 0.05,
    on_complete = nil
}

function DialogueBox.start_tree(tree, node_id, on_complete)
    DialogueBox.tree = tree
    DialogueBox.on_complete = on_complete
    DialogueBox.active = true
    DialogueBox.load_node(node_id)
end

function DialogueBox.load_node(node_id)
    if not DialogueBox.tree or not DialogueBox.tree[node_id] then
        DialogueBox.active = false
        if DialogueBox.on_complete then DialogueBox.on_complete() end
        return
    end
    
    DialogueBox.current_node = DialogueBox.tree[node_id]
    DialogueBox.text = DialogueBox.current_node.text or ""
    DialogueBox.speaker = DialogueBox.current_node.speaker or ""
    DialogueBox.display_text = ""
    DialogueBox.char_index = 0
    DialogueBox.timer = 0
end

function DialogueBox.execute_action(action, target)
    if action == "start_battle" then
        State.switch("BATTLE", target)
    elseif action == "join_party" then
        print(target .. " joined the party!")
    elseif action == "ux_up_hide" then
        print("UX Index Increased!")
    elseif action == "quest_advance" then
        local target_chap = tonumber(target)
        if target_chap and QuestTracker and QuestTracker.chapter < target_chap then
            while QuestTracker.chapter < target_chap do
                QuestTracker.advance_chapter()
            end
        end
    elseif action == "map_transition" then
        State.switch("EXPLORATION", target)
    end
end

function DialogueBox.advance()
    local node = DialogueBox.current_node
    if not node then return end
    
    if node.choices then
        ChoiceMenu.show(node.choices, function(idx, choice)
            if choice.action then
                DialogueBox.execute_action(choice.action, choice.target)
            end
            if choice.next then
                DialogueBox.load_node(choice.next)
            else
                DialogueBox.active = false
                if DialogueBox.on_complete then DialogueBox.on_complete() end
            end
        end)
    elseif node.next then
        DialogueBox.load_node(node.next)
    else
        if node.action then
            DialogueBox.execute_action(node.action, node.target)
        end
        DialogueBox.active = false
        if DialogueBox.on_complete then DialogueBox.on_complete() end
    end
end

function DialogueBox.update(dt)
    if not DialogueBox.active then return end
    
    if ChoiceMenu.active then
        ChoiceMenu.update(dt)
        return
    end
    
    if DialogueBox.char_index < #DialogueBox.text then
        DialogueBox.timer = DialogueBox.timer + dt
        if DialogueBox.timer >= DialogueBox.speed then
            DialogueBox.timer = 0
            DialogueBox.char_index = DialogueBox.char_index + 1
            DialogueBox.display_text = string.sub(DialogueBox.text, 1, DialogueBox.char_index)
            if DialogueBox.char_index % 3 == 0 then
                sfx.play("select")
            end
        end
    end
    
    if input.pressed(input.BTN1) then
        if DialogueBox.char_index < #DialogueBox.text then
            DialogueBox.char_index = #DialogueBox.text
            DialogueBox.display_text = DialogueBox.text
        else
            DialogueBox.advance()
        end
    end
end

function DialogueBox.draw()
    if not DialogueBox.active then return end
    
    local box_h = 40
    local box_y = usagi.GAME_H - box_h - 10
    local box_w = usagi.GAME_W - 20
    
    gfx.rect_fill(10, box_y, box_w, box_h, 0)
    gfx.rect(10, box_y, box_w, box_h, 7)
    
    if DialogueBox.speaker ~= "" then
        gfx.text(DialogueBox.speaker .. ":", 15, box_y + 5, 10)
        gfx.text(DialogueBox.display_text, 15, box_y + 18, 7)
    else
        gfx.text(DialogueBox.display_text, 15, box_y + 10, 7)
    end
    
    if ChoiceMenu.active then
        ChoiceMenu.draw()
    end
end

return DialogueBox
