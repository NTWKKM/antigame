local notification = {
    messages = {}
}

function notification.show(text, duration, color)
    local msg = {
        text = text,
        timer = duration or 3.0,
        y_offset = #notification.messages * 15,
        x_offset = 50,
        color = color or gfx.COLOR_WHITE
    }
    table.insert(notification.messages, msg)
    if Tween then
        Tween.to(msg, 0.3, {x_offset = 0}, Tween.easeOutQuad)
    end
end

function notification.update(dt)
    for i = #notification.messages, 1, -1 do
        local msg = notification.messages[i]
        msg.timer = msg.timer - dt
        if msg.timer <= 0 then
            table.remove(notification.messages, i)
        end
    end
end

function notification.draw()
    for i, msg in ipairs(notification.messages) do
        local alpha = math.min(1.0, msg.timer / 0.3)
        local exit_x = 0
        if msg.timer < 0.3 then
            exit_x = (1 - (msg.timer / 0.3)) * 50
        end
        local current_x = msg.x_offset + exit_x
        local y = 10 + (i - 1) * 15
        
        local w = #msg.text * 4
        local bx = usagi.GAME_W - w - 20 + current_x
        local tx = usagi.GAME_W - w - 15 + current_x
        
        gfx.rect_fill(bx, y - 2, w + 10, 11, gfx.COLOR_BLACK, alpha)
        gfx.text(msg.text, tx, y, msg.color, alpha)
    end
end

return notification
