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
    choice_menu.scale = 0
    Tween.to(choice_menu, 0.15, {scale = 1}, Tween.easeOutBack)
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
    
    local scale = choice_menu.scale or 1
    if scale < 0.05 then return end
    
    local base_w = 160
    local base_h = #choice_menu.choices * 12 + 8
    local w = base_w * scale
    local h = base_h * scale
    local x = (usagi.GAME_W - w) / 2
    local y = (usagi.GAME_H - h) / 2
    
    gfx.rect_fill(x, y, w, h, gfx.COLOR_BLACK)
    gfx.rect(x, y, w, h, gfx.COLOR_WHITE)
    
    for i, choice in ipairs(choice_menu.choices) do
        local cy = y + (4 + (i - 1) * 12) * scale
        if i == choice_menu.selected then
            gfx.text_ex(">", x + 4 * scale, cy, scale, 0, gfx.COLOR_YELLOW, 1)
            gfx.text_ex(choice.text, x + 16 * scale, cy, scale, 0, gfx.COLOR_YELLOW, 1)
        else
            gfx.text_ex(choice.text, x + 16 * scale, cy, scale, 0, gfx.COLOR_WHITE, 1)
        end
    end
end

return choice_menu
