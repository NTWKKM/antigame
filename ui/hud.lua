-- ui/hud.lua
local HUD = {
    display_res = 100,
    display_ux = 0
}
local ResolutionDecay = require("systems.resolution_decay")
local UXIndex = require("systems.ux_index")

function HUD.draw()
    if not GameState then return end
    
    -- Top left corner: RES and UX
    local res_val = GameState.res or 100
    local ux_val = GameState.ux or 0
    HUD.display_res = HUD.display_res + (res_val - HUD.display_res) * 0.1
    HUD.display_ux = HUD.display_ux + (ux_val - HUD.display_ux) * 0.1
    
    local res_str = "RES:"
    local ux_str = "UX:"
    
    local res_state = ResolutionDecay.get_resolution_state()
    
    local glitch_x = 0
    local glitch_y = 0
    if res_state == "Bit Rot" or res_state == "Dead Zone" then
        glitch_x = math.random(-1, 1)
        glitch_y = math.random(-1, 1)
    end
    
    -- Draw shadow
    gfx.text(res_str, 3 + glitch_x, 3 + glitch_y, gfx.COLOR_BLACK)
    gfx.text(ux_str, 3, 13, gfx.COLOR_BLACK)
    
    -- Draw text
    gfx.text(res_str, 2 + glitch_x, 2 + glitch_y, gfx.COLOR_WHITE)
    local ux_color = ux_val > 80 and gfx.COLOR_RED or gfx.COLOR_YELLOW
    gfx.text(ux_str, 2, 12, ux_color)
    
    -- Draw RES Bar
    gfx.rect(25, 3, 50, 6, gfx.COLOR_DARK_GRAY)
    gfx.rect_fill(25, 3, 50 * (HUD.display_res / 100), 6, gfx.COLOR_WHITE)
    
    -- Draw UX Bar
    if ux_val > 80 then
        local pulse_alpha = math.abs(math.sin(usagi.elapsed * 5))
        gfx.rect_fill(23, 11, 54, 10, gfx.COLOR_RED, pulse_alpha)
    end
    gfx.rect(25, 13, 50, 6, gfx.COLOR_DARK_GRAY)
    gfx.rect_fill(25, 13, 50 * (HUD.display_ux / 100), 6, ux_color)
    
    -- Top right corner: Current Chapter & Resolution State
    if QuestTracker then
        local q_name = QuestTracker.current_quest or ""
        local state_str = "[" .. res_state .. "]"
        
        local state_color = gfx.COLOR_GREEN
        if res_state == "Degrading" then
            state_color = gfx.COLOR_YELLOW
        elseif res_state == "Bit Rot" or res_state == "Dead Zone" then
            state_color = gfx.COLOR_RED
        end
        
        gfx.text(q_name, usagi.GAME_W - 170, 2, gfx.COLOR_YELLOW)
        gfx.text(state_str, usagi.GAME_W - 75, 12, state_color)
    end
    
    -- Bottom left: Party HP
    if Party and Party.active_party then
        for i, member_id in ipairs(Party.active_party) do
            local member = Party.members[member_id]
            if member then
                local py = usagi.GAME_H - 5 - (i * 12)
                gfx.text(member.name, 2, py, gfx.COLOR_WHITE)
                local hp_pct = member.hp / member.max_hp
                gfx.rect(30, py + 1, 30, 4, gfx.COLOR_DARK_GRAY)
                gfx.rect_fill(30, py + 1, 30 * hp_pct, 4, gfx.COLOR_GREEN)
            end
        end
    end
    
    -- Center overlay: Anomaly Warning Banner
    if UXIndex.anomaly_message then
        local msg = UXIndex.anomaly_message
        local msg_w = #msg * 6
        local mx = math.floor((usagi.GAME_W - msg_w) / 2)
        local my = 85
        
        gfx.rect_fill(mx - 4, my - 2, msg_w + 8, 12, gfx.COLOR_BLACK)
        gfx.text(msg, mx + 1, my + 1, gfx.COLOR_BLACK)
        gfx.text(msg, mx, my, gfx.COLOR_RED)
    end
end

return HUD

