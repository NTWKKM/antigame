local inventory_ui = {
    active = false
}

function inventory_ui.show()
    inventory_ui.active = true
end

function inventory_ui.hide()
    inventory_ui.active = false
end

function inventory_ui.update(dt)
    if not inventory_ui.active then return end
    if input.pressed(usagi.BTN_B) then
        inventory_ui.hide()
    end
end

function inventory_ui.draw(inventory_system)
    if not inventory_ui.active then return end
    
    gfx.rect_fill(20, 20, 280, 140, gfx.COLOR_BLACK)
    gfx.rect(20, 20, 280, 140, gfx.COLOR_WHITE)
    
    gfx.text("INVENTORY", 130, 25, gfx.COLOR_YELLOW)
    
    local y = 45
    for id, qty in pairs(inventory_system.items) do
        gfx.text(id .. " x" .. qty, 30, y, gfx.COLOR_WHITE)
        y = y + 12
    end
    
    gfx.text("Currency: " .. inventory_system.currency, 30, 145, gfx.COLOR_GREEN)
end

return inventory_ui
