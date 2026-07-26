-- ui/menu_screen.lua
local MenuScreen = {
    active = false,
    options = {"Resume", "Save", "Quit"},
    cursor = 1
}

function MenuScreen.toggle()
    MenuScreen.active = not MenuScreen.active
    if MenuScreen.active then
        MenuScreen.cursor = 1
    end
end

function MenuScreen.update(dt)
    if not MenuScreen.active then return end
    
    if input.pressed(input.UP) then
        MenuScreen.cursor = MenuScreen.cursor - 1
        if MenuScreen.cursor < 1 then MenuScreen.cursor = #MenuScreen.options end
        sfx.play("select")
    elseif input.pressed(input.DOWN) then
        MenuScreen.cursor = MenuScreen.cursor + 1
        if MenuScreen.cursor > #MenuScreen.options then MenuScreen.cursor = 1 end
        sfx.play("select")
    end
    
    if input.pressed(input.BTN1) then
        MenuScreen.select()
    end
    
    if input.pressed(input.BTN2) or input.pressed(input.BTN3) then
        MenuScreen.toggle()
    end
end

function MenuScreen.select()
    local opt = MenuScreen.options[MenuScreen.cursor]
    sfx.play("jump")
    if opt == "Resume" then
        MenuScreen.toggle()
    elseif opt == "Save" then
        usagi.save(GameState)
        print("Game Saved!")
        MenuScreen.toggle()
    elseif opt == "Quit" then
        usagi.quit()
    end
end

function MenuScreen.draw()
    if not MenuScreen.active then return end
    
    local box_w = 100
    local box_h = 80
    local box_x = (usagi.GAME_W - box_w) / 2
    local box_y = (usagi.GAME_H - box_h) / 2
    
    gfx.rect_fill(box_x, box_y, box_w, box_h, gfx.COLOR_BLACK)
    gfx.rect(box_x, box_y, box_w, box_h, gfx.COLOR_WHITE)
    
    gfx.text("PAUSE", box_x + 30, box_y + 10, gfx.COLOR_YELLOW)
    
    for i, opt in ipairs(MenuScreen.options) do
        local color = gfx.COLOR_WHITE
        if i == MenuScreen.cursor then color = gfx.COLOR_RED end
        gfx.text(opt, box_x + 20, box_y + 30 + (i * 10), color)
        if i == MenuScreen.cursor then
            gfx.text(">", box_x + 10, box_y + 30 + (i * 10), gfx.COLOR_RED)
        end
    end
end

return MenuScreen
