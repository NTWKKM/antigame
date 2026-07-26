-- battle/timeline_actions.lua
local ResolutionGauge = require("battle.resolution_gauge")
local ReactiveDefense = require("battle.reactive_defense")
local SyncTech = require("battle.sync_tech")
local Inventory = require("systems.inventory")

local Actions = {}

function Actions.execute_attack(Timeline, attacker, target, damage)
    target:take_damage(damage)
    sfx.play("hit")
    Camera.shake(2, 0.2)
    
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
                local mods = ResolutionGauge.get_modifiers()
                local base_dmg = Timeline.active_combatant.atk
                local final_dmg = math.floor(base_dmg * mods.dmg_out)
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
            local target = Actions.get_random_target(Timeline, false)
            if target then
                ReactiveDefense.start(target, skill, 1.0)
                Timeline.state = "qte"
                Timeline.target = target
            end
        end
    end
end

return Actions
