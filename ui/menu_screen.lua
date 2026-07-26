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
    frag_list = {},
    item_list = {},
    scale = 1
}

function MenuScreen.toggle()
    MenuScreen.active = not MenuScreen.active
    if MenuScreen.active then
        MenuScreen.state = "main"
        MenuScreen.cursor = 1
        MenuScreen.scale = 0
        Tween.to(MenuScreen, 0.2, {scale = 1}, Tween.easeOutBack)
    end
end

function MenuScreen.build_item_list()
    MenuScreen.item_list = {}
    for id, qty in pairs(Inventory.items) do
        if not CoreFragment.fragments[id] then
            table.insert(MenuScreen.item_list, {id=id, qty=qty})
        end
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
        local max_cursor = math.max(1, #MenuScreen.item_list)
        if input.pressed(input.UP) then
            MenuScreen.item_cursor = MenuScreen.item_cursor - 1
            if MenuScreen.item_cursor < 1 then MenuScreen.item_cursor = max_cursor end
            sfx.play("select")
        elseif input.pressed(input.DOWN) then
            MenuScreen.item_cursor = MenuScreen.item_cursor + 1
            if MenuScreen.item_cursor > max_cursor then MenuScreen.item_cursor = 1 end
            sfx.play("select")
        elseif input.pressed(input.BTN1) and #MenuScreen.item_list > 0 then
            local item = MenuScreen.item_list[MenuScreen.item_cursor]
            if item.id == "medkit" then
                for _, pid in ipairs(Party.active_party) do
                    local member = Party.members[pid]
                    if member.hp then
                        member.hp = math.min(member.hp + 50, member.max_hp or member.hp + 50)
                    end
                end
                Inventory.remove_item(item.id, 1)
                sfx.play("heal")
                MenuScreen.build_item_list()
                if MenuScreen.item_cursor > #MenuScreen.item_list then MenuScreen.item_cursor = math.max(1, #MenuScreen.item_list) end
            end
        elseif input.pressed(input.BTN2) then
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
            if MenuScreen.char_cursor > #Party.active_party then MenuScreen.char_cursor = 1 end
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
        MenuScreen.item_cursor = 1
        MenuScreen.build_item_list()
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
    
    local scale = MenuScreen.scale or 1
    if scale < 0.05 then return end
    
    local base_w = 200
    local base_h = 140
    local box_w = base_w * scale
    local box_h = base_h * scale
    local box_x = (usagi.GAME_W - box_w) / 2
    local box_y = (usagi.GAME_H - box_h) / 2
    
    gfx.rect_fill(box_x, box_y, box_w, box_h, gfx.COLOR_BLACK)
    gfx.rect(box_x, box_y, box_w, box_h, gfx.COLOR_WHITE)
    
    -- Only draw contents if fully scaled in to avoid text overflow when scaling,
    -- or just draw normally relative to box_x and box_y.
    -- For simplicity, we'll draw relative.
    if scale < 0.9 then return end
    
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
        
        local py = box_y + 30
        for i, id in ipairs(Party.active_party) do
            local c = Party.members[id]
            gfx.text(c.name, box_x + 130, py, gfx.COLOR_WHITE)
            gfx.text("HP: " .. (c.hp or 0) .. "/" .. (c.max_hp or 0), box_x + 130, py + 10, gfx.COLOR_GREEN)
            gfx.text("TP: " .. (c.tp or 0) .. "/" .. (c.max_tp or 0), box_x + 130, py + 20, gfx.COLOR_BLUE)
            py = py + 35
        end
    elseif MenuScreen.state == "items" then
        gfx.text("INVENTORY", box_x + 70, box_y + 10, gfx.COLOR_YELLOW)
        local max_vis = 8
        local start_idx = math.max(1, MenuScreen.item_cursor - math.floor(max_vis/2))
        local end_idx = math.min(#MenuScreen.item_list, start_idx + max_vis - 1)
        if end_idx - start_idx + 1 < max_vis then
            start_idx = math.max(1, end_idx - max_vis + 1)
        end
        
        if start_idx > 1 then gfx.text("^", box_x + 95, box_y + 20, gfx.COLOR_WHITE) end
        
        local y = box_y + 30
        for i = start_idx, end_idx do
            local item = MenuScreen.item_list[i]
            local color = (i == MenuScreen.item_cursor) and gfx.COLOR_RED or gfx.COLOR_WHITE
            gfx.text(item.id .. " x" .. item.qty, box_x + 20, y, color)
            if i == MenuScreen.item_cursor then
                gfx.text(">", box_x + 10, y, gfx.COLOR_RED)
            end
            y = y + 10
        end
        
        if end_idx < #MenuScreen.item_list then gfx.text("v", box_x + 95, y, gfx.COLOR_WHITE) end
        if #MenuScreen.item_list == 0 then
            gfx.text("No items in inventory", box_x + 20, box_y + 30, gfx.COLOR_RED)
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
        
        local max_vis = 6
        local start_idx = math.max(1, MenuScreen.frag_cursor - math.floor(max_vis/2))
        local end_idx = math.min(#MenuScreen.frag_list, start_idx + max_vis - 1)
        if end_idx - start_idx + 1 < max_vis then
            start_idx = math.max(1, end_idx - max_vis + 1)
        end
        
        if start_idx > 1 then gfx.text("^", box_x + 95, box_y + 18, gfx.COLOR_WHITE) end
        
        local y = box_y + 25
        for i = start_idx, end_idx do
            local fid = MenuScreen.frag_list[i]
            local frag = CoreFragment.fragments[fid]
            local color = (i == MenuScreen.frag_cursor) and gfx.COLOR_RED or gfx.COLOR_WHITE
            gfx.text(frag.name or fid, box_x + 30, y, color)
            if i == MenuScreen.frag_cursor then
                gfx.text(">", box_x + 20, y, gfx.COLOR_RED)
            end
            y = y + 15
        end
        
        if end_idx < #MenuScreen.frag_list then gfx.text("v", box_x + 95, y, gfx.COLOR_WHITE) end
        
        if #MenuScreen.frag_list == 0 then
            gfx.text("No fragments in inventory", box_x + 20, box_y + 30, gfx.COLOR_RED)
        end
    end
end

return MenuScreen
