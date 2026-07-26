-- ui/hud.lua
local HUD = {}
local ResolutionDecay = require("systems.resolution_decay")
local UXIndex = require("systems.ux_index")

function HUD.draw()
    if not GameState then return end
    
    -- Top left corner: RES and UX
    local res_val = math.floor(GameState.res or 100)
    local ux_val = math.floor(GameState.ux or 0)
    local res_str = "RES: " .. tostring(res_val) .. "%"
    local ux_str = "UX:  " .. tostring(ux_val) .. "%"
    
    -- Draw shadow
    gfx.text(res_str, 3, 3, gfx.COLOR_BLACK)
    gfx.text(ux_str, 3, 13, gfx.COLOR_BLACK)
    
    -- Draw text
    gfx.text(res_str, 2, 2, gfx.COLOR_WHITE)
    local ux_color = ux_val > 80 and gfx.COLOR_RED or gfx.COLOR_YELLOW
    gfx.text(ux_str, 2, 12, ux_color)
    
    -- Top right corner: Current Chapter & Resolution State
    if QuestTracker then
        local q_name = QuestTracker.current_quest or ""
        local res_state = ResolutionDecay.get_resolution_state()
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

