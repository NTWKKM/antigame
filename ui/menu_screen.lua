local Party = require("systems.party")
local Inventory = require("systems.inventory")
local CoreFragment = require("systems.core_fragment")

local MenuScreen = {
    active = false,
    state = "main", -- main, items, fragments_char, fragments_list
    main_options = {"Resume", "Items", "Fragments", "Save", "Quit"},
    cursor = 1,
    char_cursor = 1,
    item_cursor = 1,
    frag_cursor = 1,
    selected_char = nil,
    frag_list = {}
}

function MenuScreen.toggle()
    MenuScreen.active = not MenuScreen.active
    if MenuScreen.active then
        MenuScreen.state = "main"
        MenuScreen.cursor = 1
    end
end

function MenuScreen.update(dt)
    if not MenuScreen.active then return end
    
    if MenuScreen.state == "main" then
        if input.pressed(input.UP) then
            MenuScreen.cursor = MenuScreen.cursor - 1
            if MenuScreen.cursor < 1 then MenuScreen.cursor = #MenuScreen.main_options end
            sfx.play("select")
        elseif input.pressed(input.DOWN) then
            MenuScreen.cursor = MenuScreen.cursor + 1
            if MenuScreen.cursor > #MenuScreen.main_options then MenuScreen.cursor = 1 end
            sfx.play("select")
        elseif input.pressed(input.BTN1) then
            MenuScreen.select_main()
        elseif input.pressed(input.BTN2) or input.pressed(input.BTN3) then
            MenuScreen.toggle()
        end
        
    elseif MenuScreen.state == "items" then
        -- We will implement a proper list later if needed, for now just view
        if input.pressed(input.BTN2) then
            MenuScreen.state = "main"
            sfx.play("jump")
        end
        
    elseif MenuScreen.state == "fragments_char" then
        if input.pressed(input.UP) then
            MenuScreen.char_cursor = MenuScreen.char_cursor - 1
            if MenuScreen.char_cursor < 1 then MenuScreen.char_cursor = #Party.active_party end
            sfx.play("select")
        elseif input.pressed(input.DOWN) then
            MenuScreen.char_cursor = MenuScreen.char_cursor + 1
            if MenuScreen.char_cursor > #Party.active_party end then MenuScreen.char_cursor = 1 end
            sfx.play("select")
        elseif input.pressed(input.BTN1) then
            MenuScreen.selected_char = Party.members[Party.active_party[MenuScreen.char_cursor]]
            MenuScreen.state = "fragments_list"
            MenuScreen.frag_cursor = 1
            
            -- Build frag list (equipped + inventory)
            MenuScreen.frag_list = {}
            for id, qty in pairs(Inventory.items) do
                if CoreFragment.fragments[id] then
                    table.insert(MenuScreen.frag_list, id)
                end
            end
            sfx.play("jump")
        elseif input.pressed(input.BTN2) then
            MenuScreen.state = "main"
            sfx.play("jump")
        end
        
    elseif MenuScreen.state == "fragments_list" then
        local max_cursor = math.max(1, #MenuScreen.frag_list)
        if input.pressed(input.UP) then
            MenuScreen.frag_cursor = MenuScreen.frag_cursor - 1
            if MenuScreen.frag_cursor < 1 then MenuScreen.frag_cursor = max_cursor end
            sfx.play("select")
        elseif input.pressed(input.DOWN) then
            MenuScreen.frag_cursor = MenuScreen.frag_cursor + 1
            if MenuScreen.frag_cursor > max_cursor then MenuScreen.frag_cursor = 1 end
            sfx.play("select")
        elseif input.pressed(input.BTN1) and #MenuScreen.frag_list > 0 then
            local frag_id = MenuScreen.frag_list[MenuScreen.frag_cursor]
            -- Equip logic
            if #MenuScreen.selected_char.fragments >= 2 then
                -- Unequip first one for simplicity
                local removed = table.remove(MenuScreen.selected_char.fragments, 1)
                Inventory.add_item(removed, 1)
            end
            table.insert(MenuScreen.selected_char.fragments, frag_id)
            Inventory.remove_item(frag_id, 1)
            
            MenuScreen.state = "fragments_char"
            sfx.play("hit")
        elseif input.pressed(input.BTN2) then
            MenuScreen.state = "fragments_char"
            sfx.play("jump")
        end
    end
end

function MenuScreen.select_main()
    local opt = MenuScreen.main_options[MenuScreen.cursor]
    sfx.play("jump")
    if opt == "Resume" then
        MenuScreen.toggle()
    elseif opt == "Items" then
        MenuScreen.state = "items"
    elseif opt == "Fragments" then
        MenuScreen.state = "fragments_char"
        MenuScreen.char_cursor = 1
    elseif opt == "Save" then
        usagi.save(GameState)
    elseif opt == "Quit" then
        usagi.quit()
    end
end

function MenuScreen.draw()
    if not MenuScreen.active then return end
    
    local box_w = 200
    local box_h = 140
    local box_x = (usagi.GAME_W - box_w) / 2
    local box_y = (usagi.GAME_H - box_h) / 2
    
    gfx.rect_fill(box_x, box_y, box_w, box_h, gfx.COLOR_BLACK)
    gfx.rect(box_x, box_y, box_w, box_h, gfx.COLOR_WHITE)
    
    if MenuScreen.state == "main" then
        gfx.text("PAUSE", box_x + 80, box_y + 10, gfx.COLOR_YELLOW)
        for i, opt in ipairs(MenuScreen.main_options) do
            local color = gfx.COLOR_WHITE
            if i == MenuScreen.cursor then color = gfx.COLOR_RED end
            gfx.text(opt, box_x + 80, box_y + 30 + (i * 12), color)
            if i == MenuScreen.cursor then
                gfx.text(">", box_x + 70, box_y + 30 + (i * 12), gfx.COLOR_RED)
            end
        end
    elseif MenuScreen.state == "items" then
        gfx.text("INVENTORY", box_x + 70, box_y + 10, gfx.COLOR_YELLOW)
        local y = box_y + 30
        for id, qty in pairs(Inventory.items) do
            if not CoreFragment.fragments[id] then
                gfx.text(id .. " x" .. qty, box_x + 20, y, gfx.COLOR_WHITE)
                y = y + 10
            end
        end
    elseif MenuScreen.state == "fragments_char" then
        gfx.text("SELECT CHARACTER", box_x + 50, box_y + 10, gfx.COLOR_YELLOW)
        for i, id in ipairs(Party.active_party) do
            local c = Party.members[id]
            local color = (i == MenuScreen.char_cursor) and gfx.COLOR_RED or gfx.COLOR_WHITE
            gfx.text(c.name, box_x + 30, box_y + 20 + (i * 20), color)
            if i == MenuScreen.char_cursor then
                gfx.text(">", box_x + 20, box_y + 20 + (i * 20), gfx.COLOR_RED)
            end
            -- Show equipped
            local eq = "Eq: "
            for _, fid in ipairs(c.fragments) do eq = eq .. fid .. " " end
            gfx.text(eq, box_x + 30, box_y + 30 + (i * 20), gfx.COLOR_GREEN)
        end
    elseif MenuScreen.state == "fragments_list" then
        gfx.text("SELECT FRAGMENT", box_x + 50, box_y + 10, gfx.COLOR_YELLOW)
        for i, fid in ipairs(MenuScreen.frag_list) do
            local frag = CoreFragment.fragments[fid]
            local color = (i == MenuScreen.frag_cursor) and gfx.COLOR_RED or gfx.COLOR_WHITE
            gfx.text(frag.name or fid, box_x + 30, box_y + 20 + (i * 15), color)
            if i == MenuScreen.frag_cursor then
                gfx.text(">", box_x + 20, box_y + 20 + (i * 15), gfx.COLOR_RED)
            end
        end
        if #MenuScreen.frag_list == 0 then
            gfx.text("No fragments in inventory", box_x + 20, box_y + 30, gfx.COLOR_RED)
        end
    end
end

return MenuScreen
