-- battle/timeline.lua
local Combatant = require("battle.combatant")
local ResolutionGauge = require("battle.resolution_gauge")
local ReactiveDefense = require("battle.reactive_defense")
local SyncTech = require("battle.sync_tech")
local Inventory = require("systems.inventory")
local Actions = require("battle.timeline_actions")

local Timeline = {
    combatants = {},
    state = "active", -- active, player_turn, enemy_turn, qte, win, lose
    active_combatant = nil,
    target = nil,
    player_menu_cursor = 1,
    player_menu_options = {"Attack", "Skills", "Sync", "Items", "Defend"}
}

function Timeline.init(party_data, enemy_data)
    Timeline.combatants = {}
    
    for i, p in ipairs(party_data) do
        local c = Combatant.new(p.id, p.name, false, p)
        c.x = 240
        c.y = 40 + (i * 30)
        c.home_x = c.x
        c.home_y = c.y
        c.draw_x = c.x
        c.draw_y = c.y
        table.insert(Timeline.combatants, c)
    end
    
    for i, e in ipairs(enemy_data) do
        local c = Combatant.new(e.id, e.name, true, e)
        c.x = 60
        c.y = 40 + (i * 30)
        c.home_x = c.x
        c.home_y = c.y
        c.draw_x = c.x
        c.draw_y = c.y
        table.insert(Timeline.combatants, c)
    end
    
    ResolutionGauge.init()
    SyncTech.init()
    Timeline.state = "active"
    Timeline.player_menu_cursor = 1
end

function Timeline.update(dt)
    if FX.should_freeze() then return end
    
    if Timeline.state == "active" then
        for _, c in ipairs(Timeline.combatants) do
            c:update_atb(dt)
            if c.state == "ready" then
                Timeline.active_combatant = c
                if c.is_enemy then
                    Timeline.state = "enemy_turn"
                    Timeline.enemy_timer = 1.0
                else
                    Timeline.state = "player_turn"
                    Timeline.player_menu_cursor = 1
                    Timeline.menu_scale = 0
                    Tween.to(Timeline, 0.2, {menu_scale = 1}, Tween.easeOutBack)
                    sfx.play("select")
                end
                break
            end
        end
    elseif Timeline.state == "player_turn" then
        Actions.handle_player_menu(Timeline)
    elseif Timeline.state == "skills_menu" then
        local skills = Timeline.active_combatant.skills or {}
        local max_cursor = math.max(1, #skills)
        if input.pressed(input.UP) then
            Timeline.skill_cursor = Timeline.skill_cursor - 1
            if Timeline.skill_cursor < 1 then Timeline.skill_cursor = max_cursor end
            sfx.play("select")
        elseif input.pressed(input.DOWN) then
            Timeline.skill_cursor = Timeline.skill_cursor + 1
            if Timeline.skill_cursor > max_cursor then Timeline.skill_cursor = 1 end
            sfx.play("select")
        elseif input.pressed(input.BTN2) then
            Timeline.state = "player_turn"
            sfx.play("jump")
        elseif input.pressed(input.BTN1) and #skills > 0 then
            local skill_id = skills[Timeline.skill_cursor]
            local mods = ResolutionGauge.get_modifiers()
            local tp_cost = math.floor(10 * mods.cost)
            if Timeline.active_combatant.tp >= tp_cost then
                Timeline.active_combatant.tp = Timeline.active_combatant.tp - tp_cost
                local target = Actions.get_random_target(Timeline, true)
                if target then
                    local final_dmg = math.floor((Timeline.active_combatant.atk * 1.5) * mods.dmg_out)
                    Actions.execute_attack(Timeline, Timeline.active_combatant, target, final_dmg)
                    ResolutionGauge.apply_action(10)
                    Actions.check_overheat(Timeline)
                end
            else
                sfx.play("jump")
            end
        end
    elseif Timeline.state == "items_menu" then
        local max_cursor = math.max(1, #Timeline.item_list)
        if input.pressed(input.UP) then
            Timeline.item_cursor = Timeline.item_cursor - 1
            if Timeline.item_cursor < 1 then Timeline.item_cursor = max_cursor end
            sfx.play("select")
        elseif input.pressed(input.DOWN) then
            Timeline.item_cursor = Timeline.item_cursor + 1
            if Timeline.item_cursor > max_cursor then Timeline.item_cursor = 1 end
            sfx.play("select")
        elseif input.pressed(input.BTN2) then
            Timeline.state = "player_turn"
            sfx.play("jump")
        elseif input.pressed(input.BTN1) and #Timeline.item_list > 0 then
            local item_id = Timeline.item_list[Timeline.item_cursor]
            Inventory.remove_item(item_id, 1)
            Timeline.active_combatant.hp = math.min(Timeline.active_combatant.max_hp, Timeline.active_combatant.hp + 50)
            ResolutionGauge.apply_action(-20)
            Timeline.active_combatant:reset_atb()
            Timeline.state = "active"
            sfx.play("hit")
        end
    elseif Timeline.state == "sync_menu" then
        if input.pressed(input.UP) then
            Timeline.sync_cursor = Timeline.sync_cursor - 1
            if Timeline.sync_cursor < 1 then Timeline.sync_cursor = #Timeline.sync_options end
            sfx.play("select")
        elseif input.pressed(input.DOWN) then
            Timeline.sync_cursor = Timeline.sync_cursor + 1
            if Timeline.sync_cursor > #Timeline.sync_options then Timeline.sync_cursor = 1 end
            sfx.play("select")
        elseif input.pressed(input.BTN2) then
            Timeline.state = "player_turn"
            sfx.play("jump")
        elseif input.pressed(input.BTN1) then
            local combo = Timeline.sync_options[Timeline.sync_cursor]
            local target = Actions.get_random_target(Timeline, true)
            if target then
                local mods = ResolutionGauge.get_modifiers()
                local dmg = math.floor(Timeline.active_combatant.atk * combo.damage_mult * mods.dmg_out)
                Actions.execute_attack(Timeline, Timeline.active_combatant, target, dmg)
                ResolutionGauge.apply_action(25)
                Actions.check_overheat(Timeline)
                for _, c in ipairs(Timeline.combatants) do
                    if not c.is_enemy and (c.name == combo.req1 or c.name == combo.req2) then
                        c:reset_atb()
                    end
                end
            end
        end
    elseif Timeline.state == "enemy_turn" then
        Actions.handle_enemy_turn(Timeline, dt)
    elseif Timeline.state == "qte" then
        ReactiveDefense.update(dt)
        if ReactiveDefense.resolved then
            local mods = ResolutionGauge.get_modifiers()
            local base_dmg = Timeline.active_combatant.atk or 10
            local mitigation = ReactiveDefense.get_mitigation()
            local final_dmg = math.floor(base_dmg * mitigation * mods.dmg_in)
            Actions.execute_attack(Timeline, Timeline.active_combatant, Timeline.target, final_dmg)
            
            if ReactiveDefense.success_level == "perfect" then
                ResolutionGauge.apply_action(-5)
            elseif ReactiveDefense.success_level == "good" then
                ResolutionGauge.apply_action(-2)
            else
                ResolutionGauge.apply_action(5)
            end
            Actions.check_overheat(Timeline)
        end
    elseif Timeline.state == "win" then
        if not Timeline.win_popup_shown then
            FX.text_popup(usagi.GAME_W/2, usagi.GAME_H/2, "VICTORY", gfx.COLOR_YELLOW, 2.0)
            Timeline.win_popup_shown = true
        end
    end
end

function Timeline.execute_attack(attacker, target, damage)
    Actions.execute_attack(Timeline, attacker, target, damage)
end

function Timeline.get_random_target(is_enemy)
    return Actions.get_random_target(Timeline, is_enemy)
end

function Timeline.check_win_loss()
    local player_alive = false
    local enemy_alive = false
    
    for _, c in ipairs(Timeline.combatants) do
        if c.state ~= "dead" then
            if c.is_enemy then enemy_alive = true else player_alive = true end
        end
    end
    
    if not player_alive then Timeline.state = "lose" end
    if not enemy_alive then Timeline.state = "win" end
end

function Timeline.check_overheat()
    Actions.check_overheat(Timeline)
end

function Timeline.draw(dt)
    -- Dark navy to dark purple gradient background
    for i = 0, usagi.GAME_H, 2 do
        local alpha = i / usagi.GAME_H
        gfx.rect_fill(0, i, usagi.GAME_W, 2, gfx.COLOR_DARK_PURPLE, alpha)
        gfx.rect_fill(0, i, usagi.GAME_W, 2, gfx.COLOR_DARK_BLUE, 1 - alpha)
    end

    -- Draw Combatants
    for _, c in ipairs(Timeline.combatants) do
        if c:is_visible() then
            local spr_id = c.is_enemy and 5 or 2
            local cx = c.draw_x + c.shake_x
            local cy = c.draw_y + c.shake_y
            
            local alpha = 1.0
            if c.state == "dead" and c.death_timer > 0 then
                alpha = c.death_timer / 0.5
            end
            
            if c.flash_timer and c.flash_timer > 0 then
                if math.floor(c.flash_timer * 30) % 2 == 0 then
                    gfx.rect_fill(cx, cy, 16, 16, gfx.COLOR_WHITE, alpha)
                else
                    gfx.spr(spr_id, cx, cy, alpha)
                end
            else
                gfx.spr(spr_id, cx, cy, alpha)
            end
            
            local bar_w = 24
            gfx.rect_fill(cx - 2, cy - 5, bar_w + 2, 5, gfx.COLOR_BLACK, alpha)
            gfx.rect_fill(cx - 2, cy - 6, bar_w + 2, 5, gfx.COLOR_BLACK, alpha)
            local hp_ratio = c.hp_display / c.max_hp
            gfx.rect_fill(cx - 1, cy - 5, bar_w * hp_ratio, 3, c.is_enemy and gfx.COLOR_RED or gfx.COLOR_GREEN, alpha)
            
            local p = c.atb_display / c.atb_max
            gfx.rect_fill(cx - 2, cy + 19, bar_w + 2, 3, gfx.COLOR_BLACK, alpha)
            gfx.rect_fill(cx - 2, cy + 18, bar_w + 2, 3, gfx.COLOR_BLACK, alpha)
            gfx.rect_fill(cx - 1, cy + 19, bar_w * p, 1, gfx.COLOR_WHITE, alpha)
            
            gfx.text(c.name, cx + 1, cy + 23, gfx.COLOR_BLACK, alpha)
            gfx.text(c.name, cx, cy + 22, gfx.COLOR_WHITE, alpha)
            
            if Timeline.active_combatant == c then
                local glow_alpha = 0.3 + (math.sin(usagi.elapsed * 6) + 1) / 2 * 0.5
                gfx.rect_fill(cx - 4, cy - 8, 28, 32, gfx.COLOR_YELLOW, glow_alpha)
            end
        end
    end
    
    FX.draw_world()
    
    local gauge_state = ResolutionGauge.get_state()
    local gauge_color = gfx.COLOR_WHITE
    if gauge_state == "RESONANCE" then gauge_color = gfx.COLOR_GREEN
    elseif gauge_state == "INSTABILITY" then gauge_color = gfx.COLOR_RED end
    
    local gauge_w = 120
    local gauge_x = (usagi.GAME_W - gauge_w) / 2
    gfx.rect_fill(gauge_x + 2, 5, gauge_w, 8, gfx.COLOR_BLACK)
    gfx.rect_fill(gauge_x, 4, gauge_w, 8, gfx.COLOR_BLACK)
    local fill = (ResolutionGauge.value - ResolutionGauge.min) / (ResolutionGauge.max - ResolutionGauge.min)
    gfx.rect_fill(gauge_x + 1, 5, (gauge_w - 2) * fill, 6, gauge_color)
    
    gfx.text("[" .. gauge_state .. "]", gauge_x + 1, 15, gfx.COLOR_BLACK)
    gfx.text("[" .. gauge_state .. "]", gauge_x, 14, gauge_color)
    
    if Timeline.state == "player_turn" then
        local base_w, base_h = 110, 50
        local scale = Timeline.menu_scale or 1
        local w = base_w * scale
        local h = base_h * scale
        local menu_x = usagi.GAME_W - w - 10
        local menu_y = usagi.GAME_H - h - 10
        
        -- Optional: skip draw if scale is very small
        if scale > 0.05 then
            gfx.rect_fill(menu_x + 2, menu_y + 2, w, h, gfx.COLOR_BLACK)
            gfx.rect_fill(menu_x, menu_y, w, h, gfx.COLOR_BLACK)
            gfx.rect(menu_x, menu_y, w, h, gfx.COLOR_LIGHT_GRAY)
            
            local bounce = math.sin(usagi.elapsed * 10) * 2
            
            for i, opt in ipairs(Timeline.player_menu_options) do
                local color = gfx.COLOR_WHITE
                if i == Timeline.player_menu_cursor then color = gfx.COLOR_YELLOW end
                gfx.text(opt, menu_x + 16, menu_y + 5 + (i * 8), gfx.COLOR_BLACK)
                gfx.text(opt, menu_x + 15, menu_y + 4 + (i * 8), color)
                if i == Timeline.player_menu_cursor then
                    gfx.text(">", menu_x + 5 + bounce, menu_y + 4 + (i * 8), gfx.COLOR_YELLOW)
                end
            end
        end
    elseif Timeline.state == "skills_menu" then
        local menu_x = usagi.GAME_W - 140
        local menu_y = usagi.GAME_H - 70
        gfx.rect_fill(menu_x + 2, menu_y + 2, 130, 60, gfx.COLOR_BLACK)
        gfx.rect_fill(menu_x, menu_y, 130, 60, gfx.COLOR_BLACK)
        gfx.rect(menu_x, menu_y, 130, 60, gfx.COLOR_LIGHT_GRAY)
        gfx.text("SKILLS", menu_x + 31, menu_y + 6, gfx.COLOR_BLACK)
        gfx.text("SKILLS", menu_x + 30, menu_y + 5, gfx.COLOR_YELLOW)
        
        local skills = Timeline.active_combatant.skills or {}
        local mods = ResolutionGauge.get_modifiers()
        local cost = math.floor(10 * mods.cost)
        local bounce = math.sin(usagi.elapsed * 10) * 2
        for i, opt in ipairs(skills) do
            local color = gfx.COLOR_WHITE
            if i == Timeline.skill_cursor then color = gfx.COLOR_YELLOW end
            gfx.text(opt .. " [" .. cost .. "TP]", menu_x + 16, menu_y + 16 + (i * 8), gfx.COLOR_BLACK)
            gfx.text(opt .. " [" .. cost .. "TP]", menu_x + 15, menu_y + 15 + (i * 8), color)
            if i == Timeline.skill_cursor then
                gfx.text(">", menu_x + 5 + bounce, menu_y + 15 + (i * 8), gfx.COLOR_YELLOW)
            end
        end
    elseif Timeline.state == "items_menu" then
        local menu_x = usagi.GAME_W - 140
        local menu_y = usagi.GAME_H - 70
        gfx.rect_fill(menu_x + 2, menu_y + 2, 130, 60, gfx.COLOR_BLACK)
        gfx.rect_fill(menu_x, menu_y, 130, 60, gfx.COLOR_BLACK)
        gfx.rect(menu_x, menu_y, 130, 60, gfx.COLOR_LIGHT_GRAY)
        gfx.text("ITEMS", menu_x + 31, menu_y + 6, gfx.COLOR_BLACK)
        gfx.text("ITEMS", menu_x + 30, menu_y + 5, gfx.COLOR_YELLOW)
        
        local bounce = math.sin(usagi.elapsed * 10) * 2
        for i, opt in ipairs(Timeline.item_list or {}) do
            local qty = Inventory.items[opt] or 0
            local color = gfx.COLOR_WHITE
            if i == Timeline.item_cursor then color = gfx.COLOR_YELLOW end
            gfx.text(opt .. " x" .. qty, menu_x + 16, menu_y + 16 + (i * 8), gfx.COLOR_BLACK)
            gfx.text(opt .. " x" .. qty, menu_x + 15, menu_y + 15 + (i * 8), color)
            if i == Timeline.item_cursor then
                gfx.text(">", menu_x + 5 + bounce, menu_y + 15 + (i * 8), gfx.COLOR_YELLOW)
            end
        end
    elseif Timeline.state == "sync_menu" then
        local menu_x = usagi.GAME_W - 140
        local menu_y = usagi.GAME_H - 70
        gfx.rect_fill(menu_x + 2, menu_y + 2, 130, 60, gfx.COLOR_BLACK)
        gfx.rect_fill(menu_x, menu_y, 130, 60, gfx.COLOR_BLACK)
        gfx.rect(menu_x, menu_y, 130, 60, gfx.COLOR_LIGHT_GRAY)
        gfx.text("SYNC TECHS", menu_x + 31, menu_y + 6, gfx.COLOR_BLACK)
        gfx.text("SYNC TECHS", menu_x + 30, menu_y + 5, gfx.COLOR_YELLOW)
        
        local bounce = math.sin(usagi.elapsed * 10) * 2
        for i, opt in ipairs(Timeline.sync_options) do
            local color = gfx.COLOR_WHITE
            if i == Timeline.sync_cursor then color = gfx.COLOR_YELLOW end
            gfx.text(opt.name, menu_x + 16, menu_y + 16 + (i * 8), gfx.COLOR_BLACK)
            gfx.text(opt.name, menu_x + 15, menu_y + 15 + (i * 8), color)
            if i == Timeline.sync_cursor then
                gfx.text(">", menu_x + 5 + bounce, menu_y + 15 + (i * 8), gfx.COLOR_YELLOW)
            end
        end
    end
    
    if Timeline.state == "qte" then
        ReactiveDefense.draw()
    elseif Timeline.state == "win" then
        gfx.text("VICTORY", 130, 90, gfx.COLOR_YELLOW)
        gfx.text("Press [" .. (input.mapping_for(input.BTN1) or "Z") .. "]", 120, 105, gfx.COLOR_WHITE)
    elseif Timeline.state == "lose" then
        gfx.text("DEFEATED", 125, 90, gfx.COLOR_RED)
        gfx.text("Press [" .. (input.mapping_for(input.BTN1) or "Z") .. "]", 120, 105, gfx.COLOR_WHITE)
    end
end

return Timeline
