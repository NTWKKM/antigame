-- battle/timeline_actions.lua
local ResolutionGauge = require("battle.resolution_gauge")
local ReactiveDefense = require("battle.reactive_defense")
local SyncTech = require("battle.sync_tech")
local Inventory = require("systems.inventory")

local Actions = {}

function Actions.execute_attack(Timeline, attacker, target, damage)
    local actual_damage = target:take_damage(damage)
    sfx.play("hit")
    
    local color = actual_damage > 20 and gfx.COLOR_YELLOW or gfx.COLOR_WHITE
    FX.damage_number(target.draw_x + 8, target.draw_y, actual_damage, color)
    FX.screen_flash(gfx.COLOR_WHITE, 0.08)
    FX.request_hitstop(3)
    
    local attacker_direction = attacker.is_enemy and -1 or 1
    FX.spawn_impact(target.draw_x + 8, target.draw_y + 8, attacker_direction, 6, gfx.COLOR_WHITE)
    
    local target_x = attacker.home_x + attacker_direction * 20
    Tween.sequence(attacker, {
        {duration = 0.1, target = {draw_x = target_x}, easing = Tween.easeOutQuad},
        {duration = 0.2, target = {draw_x = attacker.home_x}, easing = Tween.easeInOutQuad}
    })
    
    attacker:reset_atb()
    Timeline.check_win_loss()
    if Timeline.state == "player_turn" then
        Timeline.state = "active"
    end
end

function Actions.get_random_target(Timeline, is_enemy)
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

function Actions.check_overheat(Timeline)
    if ResolutionGauge.value >= ResolutionGauge.max then
        sfx.play("hit")
        FX.screen_flash(gfx.COLOR_RED, 0.3)
        FX.request_hitstop(6)
        
        for _, c in ipairs(Timeline.combatants) do
            if not c.is_enemy and c.state ~= "dead" then
                FX.spawn_glitch_particles(c.draw_x + 8, c.draw_y + 8, 10)
                local dmg = math.floor(c.max_hp * 0.5)
                local actual_dmg = c:take_damage(dmg)
                FX.damage_number(c.draw_x + 8, c.draw_y, actual_dmg, gfx.COLOR_RED)
            end
        end
        ResolutionGauge.value = 0
        Timeline.check_win_loss()
    end
end

function Actions.handle_player_menu(Timeline)
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
            local target = Actions.get_random_target(Timeline, true)
            if target then
                local SkillExecutor = require("battle.skill_executor")
                local result = SkillExecutor.execute("strike", Timeline.active_combatant, target)
                
                local mods = ResolutionGauge.get_modifiers()
                local final_dmg = math.floor(result.damage * mods.dmg_out)
                
                Camera.shake(3, 0.2)
                Actions.execute_attack(Timeline, Timeline.active_combatant, target, final_dmg)
                ResolutionGauge.apply_action(5)
                Actions.check_overheat(Timeline)
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
end

function Actions.handle_enemy_turn(Timeline, dt)
    Timeline.enemy_timer = Timeline.enemy_timer - dt
    if Timeline.enemy_timer <= 0 then
        local attacker = Timeline.active_combatant
        
        local players = {}
        for _, c in ipairs(Timeline.combatants) do
            if not c.is_enemy and c.state ~= "dead" then table.insert(players, c) end
        end
        
        local EnemyAI = require("battle.enemy_ai")
        local skill, target = EnemyAI.decide_action(attacker, players)

        if skill == "overclock" then
            for _, c in ipairs(Timeline.combatants) do
                if not c.is_enemy and c.state ~= "dead" then
                    local dmg = math.floor(c.max_hp * 0.5)
                    c:take_damage(dmg)
                end
            end
            sfx.play("hit")
            Camera.shake(6, 0.5)
            attacker:reset_atb()
            Timeline.check_win_loss()
            if Timeline.state == "enemy_turn" then
                Timeline.state = "active"
            end
        else
            if target then
                Camera.shake(2, 0.2)
                ReactiveDefense.start(target, skill, 1.0)
                Timeline.state = "qte"
                Timeline.target = target
            end
        end
    end
end

return Actions
