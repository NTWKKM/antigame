local notification = {
    messages = {}
}

function notification.show(text, duration)
    table.insert(notification.messages, {
        text = text,
        timer = duration or 3.0,
        y_offset = #notification.messages * 15
    })
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
        local alpha = math.min(1.0, msg.timer)
        -- In Usagi, colors are indexed. For fading we might just not draw or dither.
        -- We'll just skip drawing if it's dead.
        local y = 10 + (i - 1) * 15
        gfx.rect_fill(320 - (#msg.text * 4) - 20, y - 2, (#msg.text * 4) + 10, 11, 1)
        gfx.print(msg.text, 320 - (#msg.text * 4) - 15, y, 7)
    end
end

return notification
