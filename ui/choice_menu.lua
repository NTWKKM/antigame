local choice_menu = {
    active = false,
    choices = {},
    selected = 1,
    callback = nil
}

function choice_menu.show(choices, callback)
    choice_menu.choices = choices
    choice_menu.callback = callback
    choice_menu.selected = 1
    choice_menu.active = true
end

function choice_menu.update(dt)
    if not choice_menu.active then return end
    
    if input.pressed(input.UP) then
        choice_menu.selected = math.max(1, choice_menu.selected - 1)
        sfx.play("select")
    elseif input.pressed(input.DOWN) then
        choice_menu.selected = math.min(#choice_menu.choices, choice_menu.selected + 1)
        sfx.play("select")
    elseif input.pressed(input.BTN1) then
        choice_menu.active = false
        sfx.play("select")
        if choice_menu.callback then
            choice_menu.callback(choice_menu.selected, choice_menu.choices[choice_menu.selected])
        end
    end
end

function choice_menu.draw()
    if not choice_menu.active then return end
    
    local w = 160
    local h = #choice_menu.choices * 12 + 8
    local x = (320 - w) / 2
    local y = (180 - h) / 2
    
    gfx.rect_fill(x, y, w, h, 1)
    gfx.rect(x, y, w, h, 7)
    
    for i, choice in ipairs(choice_menu.choices) do
        local cy = y + 4 + (i - 1) * 12
        if i == choice_menu.selected then
            gfx.text(">", x + 4, cy, 10)
            gfx.text(choice.text, x + 16, cy, 10)
        else
            gfx.text(choice.text, x + 16, cy, 7)
        end
    end
end

return choice_menu
