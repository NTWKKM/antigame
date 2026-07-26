local Tween = require("lib.tween")
local Inventory = require("systems.inventory")

local VictoryScreen = {
    state = "inactive",
    title_scale = 3,
    panel_x = 320,
    cubes_earned = 0,
    cubes_display = 0,
    items_dropped = {},
    party_members = {}
}

function VictoryScreen.init()
    VictoryScreen.state = "inactive"
end

function VictoryScreen.start(combatants)
    VictoryScreen.state = "showing"
    VictoryScreen.title_scale = 3
    VictoryScreen.panel_x = usagi.GAME_W
    VictoryScreen.cubes_earned = 0
    VictoryScreen.cubes_display = 0
    VictoryScreen.items_dropped = {}
    VictoryScreen.party_members = {}
    
    local enemy_db = usagi.read_json("data/enemies/arc1_enemies.json")
    local enemies_data = enemy_db and enemy_db.enemies or {}
    
    for _, c in ipairs(combatants) do
        if c.is_enemy then
            VictoryScreen.cubes_earned = VictoryScreen.cubes_earned + 10
            
            local template = enemies_data[c.id]
            if template and template.drops then
                for _, drop in ipairs(template.drops) do
                    local item_id = type(drop) == "string" and drop or drop.id
                    local chance = type(drop) == "table" and drop.chance or 1.0
                    if math.random() <= chance then
                        table.insert(VictoryScreen.items_dropped, item_id)
                    end
                end
            end
        else
            table.insert(VictoryScreen.party_members, c)
        end
    end
    
    Tween.to(VictoryScreen, 1.0, {title_scale = 1}, Tween.easeOutBounce)
    Tween.to(VictoryScreen, 0.8, {panel_x = usagi.GAME_W - 120}, Tween.easeOutCubic, function()
        Tween.to(VictoryScreen, 1.0, {cubes_display = VictoryScreen.cubes_earned}, Tween.easeOutQuad, function()
            VictoryScreen.state = "done"
        end)
    end)
end

function VictoryScreen.update(dt)
    if VictoryScreen.state == "inactive" then return false end
    
    if VictoryScreen.state == "done" and input.pressed(input.BTN1) then
        return true
    end
    return false
end

function VictoryScreen.draw()
    if VictoryScreen.state == "inactive" then return end
    
    gfx.rect_fill(0, 0, usagi.GAME_W, usagi.GAME_H, gfx.COLOR_BLACK, 0.7)
    
    gfx.text_ex("VICTORY", usagi.GAME_W / 2 - 30 * VictoryScreen.title_scale, 20, VictoryScreen.title_scale, 0, gfx.COLOR_YELLOW, 1)
    
    local px = VictoryScreen.panel_x
    gfx.rect_fill(px, 40, 120, usagi.GAME_H - 80, gfx.COLOR_DARK_GRAY, 0.9)
    gfx.rect(px, 40, 120, usagi.GAME_H - 80, gfx.COLOR_WHITE)
    
    gfx.text("Rewards", px + 35, 45, gfx.COLOR_WHITE)
    gfx.text(string.format("Cubes: %d", math.floor(VictoryScreen.cubes_display)), px + 10, 65, gfx.COLOR_GREEN)
    
    gfx.text("Drops:", px + 10, 85, gfx.COLOR_WHITE)
    for i, item in ipairs(VictoryScreen.items_dropped) do
        if i > 4 then
            gfx.text("...", px + 10, 85 + i * 12, gfx.COLOR_LIGHT_GRAY)
            break
        end
        gfx.text(item, px + 10, 85 + i * 12, gfx.COLOR_LIGHT_GRAY)
    end
    
    for i, p in ipairs(VictoryScreen.party_members) do
        local y = 60 + (i - 1) * 35
        gfx.text(p.name, 40, y, gfx.COLOR_WHITE)
        gfx.text(string.format("HP: %d/%d", p.hp, p.max_hp), 40, y + 10, gfx.COLOR_PINK)
        gfx.text(string.format("TP: %d/%d", p.tp, p.max_tp or 100), 40, y + 20, gfx.COLOR_BLUE)
    end
    
    if VictoryScreen.state == "done" then
        local wave_y = math.sin(usagi.elapsed * 5) * 3
        gfx.text("Press [Z] to continue", usagi.GAME_W / 2 - 50, usagi.GAME_H - 20 + wave_y, gfx.COLOR_WHITE)
    end
end

return VictoryScreen
