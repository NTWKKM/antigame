-- battle/timeline.lua
local Combatant = require("battle.combatant")
local ResolutionGauge = require("battle.resolution_gauge")
local ReactiveDefense = require("battle.reactive_defense")
local SyncTech = require("battle.sync_tech")
local Inventory = require("systems.inventory")

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
        table.insert(Timeline.combatants, c)
    end
    
    for i, e in ipairs(enemy_data) do
        local c = Combatant.new(e.id, e.name, true, e)
        c.x = 60
        c.y = 40 + (i * 30)
        table.insert(Timeline.combatants, c)
    end
    
    ResolutionGauge.init()
    SyncTech.init()
    Timeline.state = "active"
    Timeline.player_menu_cursor = 1
end

function Timeline.update(dt)
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
                    sfx.play("select")
                end
                break
            end
        end
    elseif Timeline.state == "player_turn" then
        if input.pressed(input.UP) then
            Timeline.player_menu_cursor = Timeline.player_menu_cursor - 1
            if Timeline.player_menu_cursor < 1 then Timeline.player_menu_cursor = #Timeline.player_menu_options end
            sfx.play("select")
        elseif input.pressed(input.DOWN) then
            Timeline.player_menu_cursor = Timeline.player_menu_cursor + 1
            if Timeline.player_menu_cursor > #Timeline.player_menu_options then Timeline.player_menu_cursor = 1 end
            sfx.play("select")
        end
        
        if input.pressed(input.BTN1) then
            local choice = Timeline.player_menu_options[Timeline.player_menu_cursor]
            if choice == "Attack" then
                local target = Timeline.get_random_target(true)
                if target then
                    local mods = ResolutionGauge.get_modifiers()
                    local base_dmg = Timeline.active_combatant.atk
                    local final_dmg = math.floor(base_dmg * mods.dmg_out)
                    Timeline.execute_attack(Timeline.active_combatant, target, final_dmg)
                    ResolutionGauge.apply_action(5)
                    Timeline.check_overheat()
                end
            elseif choice == "Skills" then
                Timeline.state = "skills_menu"
                Timeline.skill_cursor = 1
                sfx.play("select")
            elseif choice == "Items" then
                Timeline.state = "items_menu"
                Timeline.item_cursor = 1
                
                Timeline.item_list = {}
                for id, qty in pairs(Inventory.items) do
                    table.insert(Timeline.item_list, id)
                end
                if #Timeline.item_list > 0 then
                    sfx.play("select")
                else
                    sfx.play("jump")
                    Timeline.state = "player_turn"
                end
            elseif choice == "Sync" then
                local ready = {}
                for _, c in ipairs(Timeline.combatants) do
                    if not c.is_enemy and (c.state == "ready" or c == Timeline.active_combatant) then
                        table.insert(ready, c)
                    end
                end
                local syncs = SyncTech.get_available(ready)
                if #syncs > 0 then
                    Timeline.state = "sync_menu"
                    Timeline.sync_options = syncs
                    Timeline.sync_cursor = 1
                    sfx.play("select")
                else
                    sfx.play("jump")
                end
            elseif choice == "Defend" then
                ResolutionGauge.apply_action(-15)
                Timeline.active_combatant:reset_atb()
                Timeline.state = "active"
            end
        end
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
            local tp_cost = math.floor(10 * mods.cost) -- Base cost 10 for all for now
            if Timeline.active_combatant.tp >= tp_cost then
                Timeline.active_combatant.tp = Timeline.active_combatant.tp - tp_cost
                local target = Timeline.get_random_target(true)
                if target then
                    local final_dmg = math.floor((Timeline.active_combatant.atk * 1.5) * mods.dmg_out)
                    Timeline.execute_attack(Timeline.active_combatant, target, final_dmg)
                    ResolutionGauge.apply_action(10)
                    Timeline.check_overheat()
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
            -- Apply effect (hardcoded for now)
            Timeline.active_combatant.hp = math.min(Timeline.active_combatant.max_hp, Timeline.active_combatant.hp + 50)
            ResolutionGauge.apply_action(-20) -- Items cool the gauge
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
            local target = Timeline.get_random_target(true)
            if target then
                local mods = ResolutionGauge.get_modifiers()
                local dmg = math.floor(Timeline.active_combatant.atk * combo.damage_mult * mods.dmg_out)
                Timeline.execute_attack(Timeline.active_combatant, target, dmg)
                ResolutionGauge.apply_action(25)
                Timeline.check_overheat()
                for _, c in ipairs(Timeline.combatants) do
                    if not c.is_enemy and (c.name == combo.req1 or c.name == combo.req2) then
                        c:reset_atb()
                    end
                end
            end
        end
    elseif Timeline.state == "enemy_turn" then
        Timeline.enemy_timer = Timeline.enemy_timer - dt
        if Timeline.enemy_timer <= 0 then
            local attacker = Timeline.active_combatant
            local skill = "Strike"
            if attacker.skills and #attacker.skills > 0 then
                skill = attacker.skills[math.random(1, #attacker.skills)]
            end

            if skill == "overclock" then
                for _, c in ipairs(Timeline.combatants) do
                    if not c.is_enemy and c.state ~= "dead" then
                        local dmg = math.floor(c.max_hp * 0.5)
                        c:take_damage(dmg)
                    end
                end
                sfx.play("hit")
                Camera.shake(5, 0.5)
                attacker:reset_atb()
                Timeline.check_win_loss()
                if Timeline.state == "enemy_turn" then
                    Timeline.state = "active"
                end
            else
                local target = Timeline.get_random_target(false)
                if target then
                    ReactiveDefense.start(target, skill, 1.0)
                    Timeline.state = "qte"
                    Timeline.target = target
                end
            end
        end
    elseif Timeline.state == "qte" then
        ReactiveDefense.update(dt)
        if ReactiveDefense.resolved then
            local mods = ResolutionGauge.get_modifiers()
            local base_dmg = Timeline.active_combatant.atk or 10
            local mitigation = ReactiveDefense.get_mitigation()
            local final_dmg = math.floor(base_dmg * mitigation * mods.dmg_in)
            Timeline.execute_attack(Timeline.active_combatant, Timeline.target, final_dmg)
            
            -- QTE resolution gauge effects:
            if ReactiveDefense.success_level == "perfect" then
                ResolutionGauge.apply_action(-5)
            elseif ReactiveDefense.success_level == "good" then
                ResolutionGauge.apply_action(-2)
            else
                ResolutionGauge.apply_action(5)
            end
            Timeline.check_overheat()
        end
    end
end

function Timeline.execute_attack(attacker, target, damage)
    target:take_damage(damage)
    sfx.play("hit")
    Camera.shake(2, 0.2)
    
    attacker:reset_atb()
    Timeline.check_win_loss()
    if Timeline.state == "player_turn" then
        Timeline.state = "active"
    end
end

function Timeline.get_random_target(is_enemy)
    local valid = {}
    for _, c in ipairs(Timeline.combatants) do
        if c.is_enemy == is_enemy and c.state ~= "dead" then
            table.insert(valid, c)
        end
    end
    if #valid > 0 then
        return valid[math.random(1, #valid)]
    end
    return nil
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
    if ResolutionGauge.value >= ResolutionGauge.max then
        sfx.play("hit")
        Camera.shake(5, 0.5)
        for _, c in ipairs(Timeline.combatants) do
            if not c.is_enemy and c.state ~= "dead" then
                local dmg = math.floor(c.max_hp * 0.5)
                c:take_damage(dmg)
            end
        end
        ResolutionGauge.value = 0
        Timeline.check_win_loss()
    end
end

function Timeline.draw(dt)
    -- Draw Combatants
    for _, c in ipairs(Timeline.combatants) do
        if c.state ~= "dead" then
            local spr_id = c.is_enemy and 5 or 2
            gfx.spr(spr_id, c.x, c.y)
            
            -- HP bar
            local bar_w = 20
            local hp_ratio = c.hp / c.max_hp
            gfx.rect_fill(c.x, c.y - 4, bar_w, 3, gfx.COLOR_BLACK)
            gfx.rect_fill(c.x, c.y - 4, bar_w * hp_ratio, 3, c.is_enemy and gfx.COLOR_RED or gfx.COLOR_GREEN)
            
            -- ATB Bar
            local p = c.atb / c.atb_max
            gfx.rect_fill(c.x, c.y + 20, bar_w * p, 2, gfx.COLOR_WHITE)
            
            -- Name
            gfx.text(c.name, c.x, c.y + 24, gfx.COLOR_WHITE)
            
            -- Active indicator
            if Timeline.active_combatant == c then
                gfx.rect(c.x - 2, c.y - 6, 24, 34, gfx.COLOR_YELLOW)
            end
        end
    end
    
    -- Draw Resolution Gauge bar at top
    local gauge_state = ResolutionGauge.get_state()
    local gauge_color = gfx.COLOR_WHITE
    if gauge_state == "RESONANCE" then gauge_color = gfx.COLOR_GREEN
    elseif gauge_state == "INSTABILITY" then gauge_color = gfx.COLOR_RED end
    
    local gauge_w = 100
    local gauge_x = (usagi.GAME_W - gauge_w) / 2
    gfx.rect_fill(gauge_x, 4, gauge_w, 6, gfx.COLOR_BLACK)
    local fill = (ResolutionGauge.value - ResolutionGauge.min) / (ResolutionGauge.max - ResolutionGauge.min)
    gfx.rect_fill(gauge_x, 4, gauge_w * fill, 6, gauge_color)
    gfx.text("[" .. gauge_state .. "]", gauge_x, 12, gauge_color)
    
    -- Player action menu (during player_turn)
    if Timeline.state == "player_turn" then
        local menu_x = 200
        local menu_y = usagi.GAME_H - 50
        gfx.rect_fill(menu_x, menu_y, 110, 45, gfx.COLOR_BLACK)
        gfx.rect(menu_x, menu_y, 110, 45, gfx.COLOR_WHITE)
        for i, opt in ipairs(Timeline.player_menu_options) do
            local color = gfx.COLOR_WHITE
            if i == Timeline.player_menu_cursor then color = gfx.COLOR_YELLOW end
            gfx.text(opt, menu_x + 15, menu_y + 5 + (i * 10), color)
            if i == Timeline.player_menu_cursor then
                gfx.text(">", menu_x + 5, menu_y + 5 + (i * 10), gfx.COLOR_YELLOW)
            end
        end
    elseif Timeline.state == "skills_menu" then
        local menu_x = 180
        local menu_y = usagi.GAME_H - 70
        gfx.rect_fill(menu_x, menu_y, 130, 60, gfx.COLOR_BLACK)
        gfx.rect(menu_x, menu_y, 130, 60, gfx.COLOR_WHITE)
        gfx.text("SKILLS", menu_x + 30, menu_y + 5, gfx.COLOR_YELLOW)
        local skills = Timeline.active_combatant.skills or {}
        local mods = ResolutionGauge.get_modifiers()
        local cost = math.floor(10 * mods.cost)
        for i, opt in ipairs(skills) do
            local color = gfx.COLOR_WHITE
            if i == Timeline.skill_cursor then color = gfx.COLOR_YELLOW end
            gfx.text(opt .. " [" .. cost .. "TP]", menu_x + 15, menu_y + 15 + (i * 10), color)
            if i == Timeline.skill_cursor then
                gfx.text(">", menu_x + 5, menu_y + 15 + (i * 10), gfx.COLOR_YELLOW)
            end
        end
    elseif Timeline.state == "items_menu" then
        local menu_x = 180
        local menu_y = usagi.GAME_H - 70
        gfx.rect_fill(menu_x, menu_y, 130, 60, gfx.COLOR_BLACK)
        gfx.rect(menu_x, menu_y, 130, 60, gfx.COLOR_WHITE)
        gfx.text("ITEMS", menu_x + 30, menu_y + 5, gfx.COLOR_YELLOW)
        for i, opt in ipairs(Timeline.item_list or {}) do
            local qty = Inventory.items[opt] or 0
            local color = gfx.COLOR_WHITE
            if i == Timeline.item_cursor then color = gfx.COLOR_YELLOW end
            gfx.text(opt .. " x" .. qty, menu_x + 15, menu_y + 15 + (i * 10), color)
            if i == Timeline.item_cursor then
                gfx.text(">", menu_x + 5, menu_y + 15 + (i * 10), gfx.COLOR_YELLOW)
            end
        end
    elseif Timeline.state == "sync_menu" then
        local menu_x = 180
        local menu_y = usagi.GAME_H - 70
        gfx.rect_fill(menu_x, menu_y, 130, 60, gfx.COLOR_BLACK)
        gfx.rect(menu_x, menu_y, 130, 60, gfx.COLOR_WHITE)
        gfx.text("SYNC TECHS", menu_x + 30, menu_y + 5, gfx.COLOR_YELLOW)
        for i, opt in ipairs(Timeline.sync_options) do
            local color = gfx.COLOR_WHITE
            if i == Timeline.sync_cursor then color = gfx.COLOR_YELLOW end
            gfx.text(opt.name, menu_x + 15, menu_y + 15 + (i * 10), color)
            if i == Timeline.sync_cursor then
                gfx.text(">", menu_x + 5, menu_y + 15 + (i * 10), gfx.COLOR_YELLOW)
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
