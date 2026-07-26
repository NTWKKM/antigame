local battle_ui = {}

function battle_ui.draw_party_status(party)
    for i, member in ipairs(party) do
        -- Draw text UI at the bottom
        local y = 140 + (i - 1) * 12
        gfx.text(member.name, 10, y, 7)
        gfx.text(string.format("HP:%3d/%3d", member.hp, member.max_hp), 60, y, 8)
        gfx.text(string.format("TP:%2d/%2d", member.tp, member.max_tp), 120, y, 12)
        gfx.text(string.format("RES:%d%%", member.stats.res), 170, y, 11)
        
        -- Draw sprite on the left side of screen
        local char_x = 40
        local char_y = 60 + (i - 1) * 32
        
        -- Determine sprite ID based on name
        local sprite_id = 2 -- default Elias
        if member.name == "Vesper" then sprite_id = 3 end
        if member.name == "Lyra" then sprite_id = 4 end
        
        gfx.spr(sprite_id, char_x, char_y)
    end
end

function battle_ui.draw_enemies(enemies)
    for i, enemy in ipairs(enemies) do
        local x = 200 + (i - 1) * 32
        local y = 60 + (i - 1) * 16
        
        -- Draw enemy sprite (ID 5 for Sweepers)
        gfx.spr(5, x, y)
        
        -- HP Bar under enemy
        gfx.text(enemy.name, x - 10, y - 10, 7)
        gfx.rect_fill(x - 5, y + 18, 26, 4, 1)
        local hp_pct = enemy.hp / enemy.max_hp
        gfx.rect_fill(x - 5, y + 18, math.max(1, 26 * hp_pct), 4, 8)
    end
end

function battle_ui.draw(party, enemies)
    battle_ui.draw_party_status(party)
    battle_ui.draw_enemies(enemies)
end

return battle_ui
